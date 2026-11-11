from pathlib import Path
from lupa import LuaRuntime
import re
root=Path(__file__).resolve().parents[3]
v=root/'uw_input/vanilla_actual/animal'
u=root/'uw_input/extracted/UndeadWildlife/42/media/lua'
p=root/'uw_build/ChilaSeda_AnimalBalance_B42/42/media/lua/shared/ChilaSeda_AnimalBalance_UndeadWildlifeButchering.lua'
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
require=function() end
function copyTable(t) if type(t)~='table' then return t end local r={} for k,v in pairs(t) do r[k]=copyTable(v) end return r end
IsoDirections={SE=1,SW=2,N=3,S=4,E=5,W=6,NE=7,NW=8}
Events={OnGameBoot={callbacks={},Add=function(f) table.insert(Events.OnGameBoot.callbacks,f) end}}
getSandboxOptions=function() return {getOptionByName=function() return nil end} end
ISButcherAnimal={isValid=function() return true end}
ISGetAnimalBones={isValid=function() return true end}
ISPutAnimalOnHook={isValid=function() return true end}
''')
for f in ['Rabbit','Chicken','Raccoon','Deer','Cow','Pig','Sheep','Turkey','Rat']:
 lua.execute((v/(f+'Definitions.lua')).read_text())
for f in ['AnimalPartsDefinitions.lua','AnimalAvatarDefinition.lua','ButcheringUtil.lua']:
 lua.execute((v/f).read_text())
for f in ['shared/UndeadWildlife_Core.lua','shared/Definitions/animal/UndeadWildlife_Definitions.lua','shared/UndeadWildlife_Butchering.lua']:
 lua.execute((u/f).read_text())
lua.execute('for _,f in ipairs(Events.OnGameBoot.callbacks) do f() end; Events.OnGameBoot.callbacks={} ')
# Derive all edible mappings from supplied source, not a separate expected list.
pairs=re.findall(r'key = "(infected\w+)"\s*,\s*source = "(\w+)"',(u/'shared/Definitions/animal/UndeadWildlife_Definitions.lua').read_text())
lua.globals().mapping=lua.table_from(dict(pairs))
lua.execute((root/'uw_build/tests/harness.lua').read_text())
lua.execute('baseline = collect()')
lua.execute(p.read_text())
lua.execute('for _,f in ipairs(Events.OnGameBoot.callbacks) do f() end')
lua.execute('validate()')
