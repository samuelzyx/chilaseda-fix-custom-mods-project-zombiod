"""Compile/package the bridge and verify disk behavior plus the real Error Magnifier parser."""
import argparse
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile
import zipfile

from lupa import LuaRuntime

args_parser = argparse.ArgumentParser()
args_parser.add_argument('--java', required=True)
args_parser.add_argument('--compiler', required=True)
args_parser.add_argument('--zombie-buddy', required=True)
args_parser.add_argument('--magnifier', required=True)
args = args_parser.parse_args()
root = Path(__file__).resolve().parents[2]
native_source = Path(args.magnifier).read_bytes()
native_hash = hashlib.sha256(native_source).hexdigest()
addon_path = root / '42/media/lua/client/zz_ChilaSeda_ErrorSessionLogs.lua'
addon_bytes = addon_path.read_bytes()
assert not addon_bytes.startswith(b'\xef\xbb\xbf'), 'Lua must not have a BOM'

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
clock=0; messages={}; rawErrors={}; starts=0; flushes=0; ends=0; reports={}; failWrite=false
function print(text) messages[#messages+1]=text end
function getTimestampMs() return clock end
function getCore() return {getVersion=function() return '42.21 fixture' end} end
function getSteamModeActive() return true end
function isClient() return false end
Calendar={YEAR=1,MONTH=2,DAY_OF_MONTH=3,getInstance=function()
 return {get=function(_,field) return ({2026,9,27})[field] end}
end}
ISCollapsableWindow={derive=function() return {} end}
MainScreen={onEnterFromGame=function()end,onReturnToGame=function()end}
Events={}
for _,name in ipairs({'OnTickEvenPaused','OnFETick','OnGameStart','OnMainMenuEnter'}) do
 local handlers={}
 Events[name]={handlers=handlers,Add=function(fn) handlers[#handlers+1]=fn end}
end
function fire(name) for _,fn in ipairs(Events[name].handlers) do fn() end end
function getLuaDebuggerErrors()
 return {size=function()return #rawErrors end,get=function(_,i)return rawErrors[i+1]end}
end
''')
magnifier = lua.execute(native_source.decode('utf-8-sig'))
lua.globals().magnifier = magnifier
lua.execute('''
function require(name) assert(name=='errorMagnifier_Main');return magnifier end
magnifier.Button={setVisible=function()end}
function pushError(text)
 rawErrors[#rawErrors+1]=text
 magnifier.parseErrors()
end
traceA='Lua((MOD:Hunter Expansion)).filthOf(HE_Detect.lua:105)\\njava.lang.RuntimeException: missing getter'
traceB='Lua((MOD:OtherMod)).call(Other.lua:1)\\njava.lang.RuntimeException: second problem'
''')
lua.execute(addon_bytes.decode('utf-8'))
lua.execute('''
pushError(traceA);pushError(traceA)
fire('OnTickEvenPaused');assert(starts==0, 'no menu-only session file')
fire('OnGameStart');assert(starts==0, 'late Java bridge must keep pending errors')
ChilaErrorLogJ={
 beginGame=function(header) starts=starts+1;reports[starts]={};return 'Error_fixture_'..starts..'.txt' end,
 record=function(text,count)
  reports[starts][text]=(reports[starts][text] or 0)+tonumber(count);return true
 end,
 flush=function()flushes=flushes+1;return not failWrite end,
 endGame=function()ends=ends+1;return true end,
 lastError=function()return 'fixture disk error' end
}
clock=1000;fire('OnTickEvenPaused')
assert(starts==1 and reports[1][traceA]==2, 'startup errors retained')
for _=1,10 do pushError(traceA) end
pushError(traceB)
clock=2000;fire('OnTickEvenPaused')
assert(reports[1][traceA]==12 and reports[1][traceB]==1, 'native parser counts')
local before=flushes
fire('OnFETick');assert(flushes==before, 'one-second I/O throttle')
-- The real Clear button replaces both collections. Keep the session totals.
magnifier.parsedErrors={};magnifier.parsedErrorsKeyed={};magnifier.errorCount=#rawErrors
pushError(traceA)
failWrite=true;clock=3000;fire('OnTickEvenPaused')
assert(reports[1][traceA]==13)
failWrite=false;clock=4000;fire('OnTickEvenPaused')
assert(reports[1][traceA]==13, 'flush retry must not count the trace twice')
pushError(traceB);fire('OnMainMenuEnter')
assert(ends==1 and reports[1][traceB]==2, 'exit flush captures the final error')
pushError(traceB)
fire('OnGameStart')
assert(starts==2 and reports[2][traceB]==1 and reports[2][traceA]==nil, 'game-session boundary')
''')
lua.execute(addon_bytes.decode('utf-8'))
lua.execute('''
assert(#Events.OnTickEvenPaused.handlers==1 and #Events.OnGameStart.handlers==1, 'reload guard')
assert(magnifier.parsedErrors[traceB]==2, 'original Magnifier state preserved')
''')
print('PASS Lua: real Error Magnifier parser; startup capture; late Java; unique traces and exact counters; clear handling; paused/menu callbacks; throttle; retry without double counting; separate game sessions; original UI/parser state preserved.')

with tempfile.TemporaryDirectory(prefix='ChilaSedaErrorLogs-') as directory:
    work = Path(directory).resolve()
    assert work.parent == Path(tempfile.gettempdir()).resolve()
    assert work.name.startswith('ChilaSedaErrorLogs-')
    classes = work / 'classes'
    classes.mkdir()
    compile_command = [args.java, '-jar', args.compiler, '-17', '-encoding', 'UTF-8', '-proc:none',
                       '-cp', args.zombie_buddy, '-d', str(classes),
                       str(root / 'source/chilaseda/ErrorLogsMain.java'),
                       str(root / 'tests/errorlogs/SessionLogHarness.java')]
    subprocess.run(compile_command, check=True)
    subprocess.run([args.java, '-cp', str(classes), 'chilaseda.errorlogs.SessionLogHarness',
                    str(work / 'game-cache')], check=True)
    jar_path = work / 'ChilaSedaErrorLogs.test.jar'
    jar_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(jar_path, 'w', compression=zipfile.ZIP_DEFLATED) as jar:
        jar.writestr('META-INF/MANIFEST.MF', 'Manifest-Version: 1.0\n\n')
        for item in sorted((classes / 'chilaseda/errorlogs').glob('Main*.class')):
            jar.write(item, item.relative_to(classes).as_posix())
    with zipfile.ZipFile(jar_path) as jar:
        assert set(jar.namelist()) == {'META-INF/MANIFEST.MF', 'chilaseda/ErrorLogsMain.class',
                                      'chilaseda/ErrorLogsMain$Entry.class'}
        assert jar.testzip() is None
    print('PASS JAR: real ZombieBuddy annotation; Java 17 bytecode; only exporter classes, no test/game/library classes.')
    print('JAR SHA256=' + hashlib.sha256(jar_path.read_bytes()).hexdigest())

assert hashlib.sha256(Path(args.magnifier).read_bytes()).hexdigest() == native_hash
print('PASS: original Workshop source unchanged. In-game integration remains pending.')
print('Error Magnifier source SHA256=' + native_hash)
