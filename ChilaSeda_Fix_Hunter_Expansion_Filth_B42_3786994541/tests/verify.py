"""Run with Lupa and a path to the installed Hunter Expansion HE_Detect.lua."""
import hashlib
import sys
from pathlib import Path

from lupa import LuaRuntime

original_path = Path(sys.argv[1])
original_bytes = original_path.read_bytes()
source_hash = hashlib.sha256(original_bytes).hexdigest()
patch_path = Path(__file__).resolve().parents[1] / "42/media/lua/shared/ChilaSeda_HunterExpansionFilthFix.lua"
patch_bytes = patch_path.read_bytes()
assert not patch_bytes.startswith(b"\xef\xbb\xbf"), "Lua patch must not have a UTF-8 BOM"

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute("""
messages = {}
function print(message) messages[#messages + 1] = message end
hooks = { tick = {}, start = {} }
Events = {
    OnTick = { Add = function(fn) hooks.tick[#hooks.tick + 1] = fn end },
    OnGameStart = { Add = function(fn) hooks.start[#hooks.start + 1] = fn end }
}
Perks = { Sneak = 'Sneak' }
caughtErrors = 0
local actualPcall = pcall
function pcall(fn, ...)
    local ok, value = actualPcall(fn, ...)
    if not ok then caughtErrors = caughtErrors + 1 end
    return ok, value
end
function garment(dirt, blood)
    return {
        getDirtiness = function() return dirt end,
        getBloodLevel = function() return blood end
    }
end
function playerWith(items, sneaking, level)
    local worn = {
        size = function() return #items end,
        get = function(_, index)
            local item = items[index + 1]
            return { getItem = function() return item end }
        end
    }
    return {
        getWornItems = function() return worn end,
        isSneaking = function() return sneaking or false end,
        getPerkLevel = function() return level or 0 end
    }
end
function require(name)
    assert(name == 'HE_Detect')
    return HEDetect
end
""")
lua.execute(original_bytes.decode("utf-8-sig"))
lua.execute("""
-- Reproduce a worn object with no dirt getter and another with neither getter.
mixedPlayer = playerWith({garment(20, 1), {getBloodLevel = function() return 2 end}, {}})
baselineMixed = HEDetect.filthOf(mixedPlayer)
assert(baselineMixed == 50)
assert(caughtErrors == 3, 'original should attempt three missing methods')
baselineErrors = caughtErrors
originalDistanceFor = HEDetect.distanceFor
originalApply = HEDetect.apply
originalSpecies = HEDetect.SPECIES
caughtErrors = 0
""")
lua.execute(patch_bytes.decode("utf-8"))
lua.execute("""
assert(HEDetect.filthOf(mixedPlayer) == baselineMixed)
assert(caughtErrors == 0, 'missing methods must never be invoked')
assert(HEDetect.filthOf(nil) == 0)
assert(HEDetect.filthOf({getWornItems = function() return nil end}) == 0)
assert(HEDetect.filthOf(playerWith({})) == 0)
assert(HEDetect.filthOf(playerWith({garment(20, 1)})) == 45)
assert(HEDetect.filthOf(playerWith({garment(80, 0), garment(10, 1)})) == 80)
assert(HEDetect.filthOf(playerWith({garment(90, 1)})) == 100)
assert(HEDetect.filthOf(playerWith({garment('not numeric', nil)})) == 0)
assert(HEDetect.filthOf(playerWith({{getDirtiness = 20, getBloodLevel = 'not callable'}})) == 0)
HEDetect.BLOOD_WEIGHT = 10
assert(HEDetect.filthOf(playerWith({garment(20, 1)})) == 30)
HEDetect.BLOOD_WEIGHT = 25
local standing = HEDetect.distanceFor(playerWith({garment(0, 0)}))
local crouched = HEDetect.distanceFor(playerWith({garment(0, 0)}, true, 5))
local filthy = HEDetect.distanceFor(playerWith({garment(50, 0)}, true, 10))
assert(standing == 14)
assert(math.abs(crouched - 9.45) < 0.000001)
assert(filthy == 19)
assert(HEDetect.distanceFor == originalDistanceFor and HEDetect.apply == originalApply)
assert(HEDetect.SPECIES == originalSpecies)
assert(#hooks.tick == 1 and #hooks.start == 1)
for _ = 1, 1000 do assert(HEDetect.filthOf(mixedPlayer) == 50) end
assert(caughtErrors == 0)
fixedFunction = HEDetect.filthOf
messageCount = #messages
""")
lua.execute(patch_bytes.decode("utf-8"))
lua.execute("""
assert(HEDetect.filthOf == fixedFunction and #messages == messageCount)
assert(#hooks.tick == 1 and #hooks.start == 1)
""")
assert hashlib.sha256(original_path.read_bytes()).hexdigest() == source_hash
print("PASS: original reproduces 3 missing-method errors; patched calculation produces 0.")
print("PASS: mixed worn items, missing/non-callable getters, numeric fallbacks, empty player/inventory, maximum and cap, configurable blood weight.")
print("PASS: original detection distances and hooks preserved; 1000 repeated checks; reload guard; Lua UTF-8 without BOM; Workshop source unchanged.")
print("Mock API verification with the installed HE_Detect.lua; in-game verification pending.")
print("HE_Detect.lua SHA256=" + source_hash)
