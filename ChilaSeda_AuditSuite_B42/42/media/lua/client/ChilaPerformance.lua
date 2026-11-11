-- Observation only. No Workshop code replaced or monkey-patched.
if ChilaPerf then return end
ChilaPerf = {ready=false, autoTest=true, contextAt=0, lastWarn=0, states={}, scanned=0}
local P=ChilaPerf
local function warn(s)
 local n=getTimestampMs()
 if n-P.lastWarn>30000 then print('[ChilaPerf] ERROR '..tostring(s)); P.lastWarn=n end
end
local function val(o,m)
 if not o then return 'UNAVAILABLE:no_object' end
 local ok,r=pcall(function() return o[m](o) end)
 if not ok or r==nil then return 'UNAVAILABLE:'..m end
 return tostring(r)
end
local function stateLabel(state)
 if state==nil then return 'UNAVAILABLE:no_state' end
 -- AI states are Java objects without Lua-exposed getName. Even a failed
 -- lookup inside pcall is logged by Kahlua; tostring avoids that lookup.
 return (tostring(state):gsub('@%x+$',''))
end
local function context()
 local player=getPlayer()
 if not player then return 'player=UNAVAILABLE:no_player' end
 local x,y,z=player:getX(),player:getY(),player:getZ()
 local now=getTimestampMs()
 local speed='UNAVAILABLE:first_sample'
 if P.prev and now>P.prev.t then speed=math.sqrt((x-P.prev.x)^2+(y-P.prev.y)^2)*1000/(now-P.prev.t) end
 P.prev={x=x,y=y,t=now}
 local s={'context_utc_ms='..now,'player_xyz='..x..','..y..','..z,'speed_tiles_s='..tostring(speed),'running='..val(player,'isRunning'),'sprinting='..val(player,'isSprinting')}
 local cell=getCell()
 local list=cell and cell:getZombieList()
 if list then
  local total=list:size()
  local count=0
  local out={}
  local transitions={}
  local budget=math.min(total,128)
  local start=total>0 and (P.scanned%total) or 0
  local seen={}
  for j=0,budget-1 do
   local index=(start+j)%total
   local zombie=list:get(index)
   if zombie then
    local zx,zy=zombie:getX(),zombie:getY()
    if (zx-x)^2+(zy-y)^2<=900 then
     count=count+1
     local id=val(zombie,'getID')
     local state=val(zombie,'getCurrentStateName')
     local flags='state='..state..',prone='..val(zombie,'isProne')..',crawler='..val(zombie,'isCrawling')..',onFloor='..val(zombie,'isOnFloor')
     if P.states[id] and P.states[id]~=flags then transitions[#transitions+1]=id..':'..P.states[id]..'->'..flags end
     seen[id]=flags
     if #out<24 then out[#out+1]=id..':'..flags end
    end
   end
  end
  P.scanned=start+budget
  -- For partial scans preserve observed states up to a bounded count, then reset.
  if total<=128 then P.states=seen else
   local size=0;for _ in pairs(P.states) do size=size+1 end
   if size>512 then P.states={} end
   for id,flags in pairs(seen) do P.states[id]=flags end
  end
  s[#s+1]='loaded_zombies='..total
  s[#s+1]='nearby_radius_tiles=30 nearby_observed='..count..' scanned='..budget..' count_complete='..tostring(total<=128)
  s[#s+1]='zombie_states=['..table.concat(out,';')..'] states_truncated='..tostring(count>#out)
  s[#s+1]='transitions=['..table.concat(transitions,';')..'] transition_resolution=poll_250ms_or_slower_partial_scan'
 else s[#s+1]='zombies=UNAVAILABLE:no_list' end
 local sq=player:getSquare()
 s[#s+1]='player_tile_z='..val(sq,'getZ')..' player_chunk_xy='..math.floor(x/10)..','..math.floor(y/10)..' chunk_loading=UNAVAILABLE:no_verified_hook'
 return table.concat(s,' ')
end
function ChilaPerf.selftest()
 if not P.ready then print('[ChilaPerf] SELFTEST WAIT: Java not ready');return end
 print('[ChilaPerf] SELFTEST '..tostring(ChilaPerfJ.selftest()))
end
function ChilaPerf.status()
 if P.ready then print('[ChilaPerf] '..tostring(ChilaPerfJ.status())) end
end
local function tick()
 local ok,err=pcall(function()
  if not P.ready then
   if not ChilaPerfJ then warn('JAVA_UNAVAILABLE: ChilaPerfJ not exposed');return end
   local path=ChilaPerfJ.startGame()
   P.ready=true
   print('[ChilaPerf] LUA_EXECUTING log='..tostring(path))
   if P.autoTest then ChilaPerf.selftest() end
  end
  local now=getTimestampMs()
  if now-P.contextAt>=250 then
   P.contextAt=now
   local begin=ChilaPerfJ.monotonicMs()
   local good,data=pcall(context)
   local cost=ChilaPerfJ.monotonicMs()-begin
   ChilaPerfJ.context((good and data or ('context=UNAVAILABLE:'..tostring(data)))..' context_collect_ms='..tostring(cost))
  end
  ChilaPerfJ.tick()
 end)
 if not ok then warn(err) end
end
Events.OnTick.Add(tick)
if Events.OnRenderTick then
 Events.OnRenderTick.Add(function() if P.ready then local ok,err=pcall(function() ChilaPerfJ.renderPulse() end);if not ok then warn(err) end end end)
 print('[ChilaPerf] RENDER_HOOK_REGISTERED OnRenderTick (execution verified in samples)')
end
print('[ChilaPerf] LUA_LOADED v0.1.1; auto SELFTEST after 8s buffer + 4s post; run unpaused')

if Events.OnAIStateChange then
 Events.OnAIStateChange.Add(function(character,newState,oldState)
  if not P.ready then return end
  local ok,err=pcall(function()
   if not character or not instanceof(character,'IsoZombie') then return end
   local player=getPlayer();if not player then return end
   local dx,dy=character:getX()-player:getX(),character:getY()-player:getY()
   if dx*dx+dy*dy>900 then return end
   ChilaPerfJ.mark('AI_STATE_CHANGE zombie_id='..val(character,'getID')..' old='..stateLabel(oldState)..' new='..stateLabel(newState)..' xyz='..character:getX()..','..character:getY()..','..character:getZ()..' crawler='..val(character,'isCrawling')..' prone='..val(character,'isProne'))
  end)
  if not ok then warn(err) end
 end)
 print('[ChilaPerf] AI_STATE_HOOK_REGISTERED; state changes within 30 tiles')
end
if Events.LoadChunk then
 Events.LoadChunk.Add(function() if P.ready then local ok,err=pcall(function() ChilaPerfJ.chunkLoaded() end);if not ok then warn(err) end end end)
end
