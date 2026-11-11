from lupa import LuaRuntime
from pathlib import Path
L=LuaRuntime(unpack_returned_tuples=True)
L.execute('''
clock=0; messages={}; captured={}; ticks=0; renders=0
function print(s) table.insert(messages,s) end
function getTimestampMs() return clock end
function getCacheDir() return 'TEST_CACHE' end
Events={OnTick={Add=function(f) onTick=f end},OnRenderTick={Add=function(f) onRender=f end},OnAIStateChange={Add=function(f) onState=f end},LoadChunk={Add=function(f) onChunk=f end}}
player={getX=function()return 123 end,getY=function()return 456 end,getZ=function()return 0 end,isRunning=function()return true end,isSprinting=function()return false end,getSquare=function()return {getZ=function()return 0 end} end}
state='ZombieIdleState'
z={getID=function()return 42 end,getZ=function()return 0 end,getX=function()return 124 end,getY=function()return 456 end,getCurrentStateName=function()return state end,isProne=function()return false end,isCrawling=function()return false end,isOnFloor=function()return false end}
list={size=function()return 1 end,get=function()return z end}
function instanceof(o,n)return o==z and n=='IsoZombie' end
function getPlayer()return player end
function getCell()return {getZombieList=function()return list end} end
''')
source=(Path(__file__).resolve().parents[2] / '42/media/lua/client/ChilaPerformance.lua').read_text(encoding='utf-8')
L.execute(source)
L.execute('clock=31000;onTick()')
assert any('JAVA_UNAVAILABLE' in v for v in L.globals().messages.values())
L.execute('''
ChilaPerfJ={startGame=function()return 'TEST_CACHE/ChilaPerformance.log' end,
 selftest=function()return 'PENDING' end,context=function(s)table.insert(captured,s)end,
 mark=function(s)marker=s end,chunkLoaded=function()chunk=true end,tick=function()ticks=ticks+1 end,renderPulse=function()renders=renders+1 end,monotonicMs=function()return clock end}
onTick();onRender();clock=clock+250;state='ZombieAttackState';onTick()
''')
a=list(L.globals().captured.values())
assert 'player_xyz=123,456,0' in a[0] and 'nearby_observed=1' in a[0]
assert 'ZombieIdleState' in a[1] and '->state=ZombieAttackState' in a[1]
L.execute('''
stateLookups=0
function javaState(name)
 return setmetatable({}, {
  __tostring=function() return 'zombie.ai.states.'..name..'@38ac4970' end,
  __index=function(_,key)
   stateLookups=stateLookups+1
   error('attempted index: '..key..' of non-table: Java state fixture')
  end
 })
end
onChunk()
''')
for name in ('GenericDefaultState', 'ZombieTurnAlerted', 'ZombieHitReactionState', 'ZombieFaceTargetState'):
    L.globals().nextState=name
    L.execute("onState(z,javaState(nextState),javaState('GenericDefaultState'))")
    assert f'old=zombie.ai.states.GenericDefaultState new=zombie.ai.states.{name}' in L.globals().marker
    assert '@' not in L.globals().marker
L.execute('onState(z,nil,nil)')
assert 'old=UNAVAILABLE:no_state new=UNAVAILABLE:no_state' in L.globals().marker
assert L.globals().stateLookups==0 and L.globals().chunk
assert L.globals().ticks==2 and L.globals().renders==1
L.execute('list.size=function()return 10000 end;clock=clock+250;onTick()')
assert 'scanned=128 count_complete=false' in list(L.globals().captured.values())[-1]
L.execute('player.getX=function()error("fixture failure")end;clock=clock+250;onTick()')
assert 'context=UNAVAILABLE:' in list(L.globals().captured.values())[-1]
assert L.globals().ticks==4
L.execute(source)
print('PASS Lua late Java activation; player values; sampled zombie transition; four non-indexable Java state fixtures and nil states with zero method lookups; render callback execution; scan cap 128; errors remain explicit; tick continues; reload guard. Mock PZ API, not an in-game test.')
