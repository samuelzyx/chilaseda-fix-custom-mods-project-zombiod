Perks={Butchering=1}
isClient=function() return false end
function round(x,n) local s=10^(n or 0) return math.floor(x*s+.5)/s end
function ZombRand(a,b) if b==nil then b=a;a=0 end if a==b then return a end return math.floor(a+(b-a)*math.random()) end
function ZombRandFloat(a,b) return a+(b-a)*math.random() end
function instanceof(o,c) return o.class==c end
function getText(s,...) return s end
function sendAddItemToContainer() end
function sendAddItemsToContainer() end
function addXp() end
function syncVisuals() end
function syncClothingFields() end
function sendHumanVisual() end
function addBloodSplat() end
function log(...) error('Unexpected vanilla log') end
DebugType={Animal=1}
function instanceItem(name)
 local t={class='Food',name=name,baseHunger=-.1,hungChange=-.1,calories=100,lipids=10,proteins=20,carbohydrates=5,age=0}
 function t:getDisplayName() return self.name end
 function t:getOffAgeMax() return 100 end
 function t:setName() end
 function t:setCustomName() end
 for _,pair in ipairs{{'BaseHunger','baseHunger'},{'HungChange','hungChange'},{'HungerChange','hungChange'},{'Calories','calories'},{'Lipids','lipids'},{'Proteins','proteins'},{'Carbohydrates','carbohydrates'},{'Age','age'}} do
   local prop=pair[2]; t['get'..pair[1]]=function(self) return self[prop] end;t['set'..pair[1]]=function(self,x) self[prop]=x end
 end
 return t
end
function AnimalDefinitions.getDef(kind)
 local def=AnimalDefinitions.animals[kind]
 return {getBreedByName=function(_,breed)
   local b=def.breeds[breed]
   return {getFeatherItem=function() return b.featherItem end}
 end}
end
function serialize(items)
 local out={}
 for _,t in ipairs(items) do out[#out+1]=table.concat({t.name,t.hungChange,t.calories,t.lipids,t.proteins,t.carbohydrates,t.age},':') end
 return table.concat(out,'|')
end
function run(kind,breed,size,ratio,skill,age,road)
 math.randomseed(9981)
 local inv={items={}}
 function inv:AddItem(t) if type(t)=='string' then t=instanceItem(t) end self.items[#self.items+1]=t;return t end
 function inv:AddItems(name,n) for i=1,n do self:AddItem(name) end return nil end
 local player={getPerkLevel=function() return skill end,getInventory=function() return inv end,addBlood=function() end}
 local md={AnimalType=kind,AnimalBreed=breed,parts=true,head=true,animalRotStage=0,meatRatio=ratio,deathAge=age,roadKill=road,MaxFeather=5,BloodQty=0}
 local avatar=AnimalAvatarDefinition[kind]
 if (not avatar or not avatar.hook) and ButcheringUtil.getLeather(kind..breed) then md.babyLeather=true end
 local c={class='IsoDeadBody',getModData=function() return md end,getAnimalType=function() return kind end,getBreed=function() return breed end,getAnimalSize=function() return size end,getCarcassName=function() return kind..breed end,isAnimalSkeleton=function() return false end,getSquare=function() return nil end,changeRotStage=function() end,invalidateCorpse=function() end}
 ButcheringUtil.butcherAnimalFromGround(c,player,false)
 return serialize(inv.items),md,c,player
end
function collect()
 local r={}
 for infected,source in pairs(mapping) do
   local breed=next(AnimalDefinitions.animals[source].breeds)
   local a=run(source,breed,1,.9,4,0,false)
   local b=run(infected,breed,1,.9,4,0,false)
   r[infected]=(a==b)
 end
 return r
end
function equal(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
function validate()
 local cases=0; local species=0
 for infected,source in pairs(mapping) do
  species=species+1
  local sd,id=AnimalDefinitions.animals[source],AnimalDefinitions.animals[infected]
  assert(sd.minSize==id.minSize and sd.maxSize==id.maxSize)
  assert(sd.minWeight==id.minWeight and sd.maxWeight==id.maxWeight)
  for breed in pairs(sd.breeds) do
   -- Vanilla mutates missing part defaults during use. Canonicalize both before comparison.
   local sa,ia=AnimalPartsDefinitions.animals[source..breed],AnimalPartsDefinitions.animals[infected..breed]
   for _,d in ipairs{sa,ia} do for _,list in ipairs{d.parts,d.bones} do for _,p in pairs(list or {}) do p.minNb=p.minNb or -1;p.maxNb=p.maxNb or -1;p.nb=p.nb or -1 end end end
   assert(equal(sa,ia),'Different parts '..infected..breed)
   for _,size in ipairs{.7,1,1.3} do for _,ratio in ipairs{.6,1} do for _,skill in ipairs{0,5,10} do for _,age in ipairs{0,30} do for _,road in ipairs{false,true} do
    local a=run(source,breed,size,ratio,skill,age,road)
    local b=run(infected,breed,size,ratio,skill,age,road)
    assert(a==b,'Yield differs '..infected..breed)
    assert(AnimalAvatarDefinition[infected]==nil,'Avatar leaked')
    cases=cases+1
   end end end end end
  end
  print(infected..' -> '..source..': before='..(baseline[infected] and 'equal' or 'DIFFERENT')..', patched=equal')
 end
 -- Existing corpse exclusion, exact forwarding, errors and restoration.
 local kind='infectedcow';local breed=next(AnimalDefinitions.animals.cow.breeds)
 local _,md,c,player=run(kind,breed,1,1,0,0,false)
 md.UndeadWildlifeNoButcher=true;md.parts=true
 assert(ButcheringUtil.butcherAnimalFromGround(c,player,false)==nil)
 assert(md.parts==true)
 md.UndeadWildlifeNoButcher=nil
 local saved=instanceItem;instanceItem=function() error('TEST_SENTINEL') end
 local ok,err=pcall(function() ButcheringUtil.addAnimalPart({item='X',nb=1},player,c,true) end)
 instanceItem=saved
 assert(not ok and string.find(err,'TEST_SENTINEL'))
 assert(AnimalAvatarDefinition[kind]==nil)
 -- Exercise the real setAnimalBodyData path for new corpses.
 for infected,source in pairs(mapping) do
  local breed=next(AnimalDefinitions.animals[source].breeds)
  local function body(kind)
   local a={getAnimalType=function() return kind end,getBreed=function() return {getName=function() return breed end} end,
    getBloodQuantity=function() return 2 end,getFeatherNumber=function() return 5 end,shouldBeSkeleton=function() return false end,
    getUsedGene=function() return {getCurrentValue=function() return .91 end} end,isBaby=function() return false end,
    getCorpseSize=function() return 2 end,getAnimalOriginalSize=function() return .9 end,getCorpseLength=function() return 3 end,
    getAnimalSize=function() return 1.1 end,getAnimalTrailerSize=function() return 4 end,isRoadKill=function() return false end,
    getData=function() return {getPregnancyTime=function() return 0 end,getPregnantPeriod=function() return 1 end,getWoolQuantity=function() return 0 end} end}
   local md={};setAnimalBodyData(a,md);md.AnimalType=nil;return md
  end
  assert(equal(body(infected),body(source)),'Body metadata differs '..infected)
  assert(AnimalAvatarDefinition[infected]==nil)
 end
 print('PASS: new corpse metadata parity for all 16 variants.')
 print('PASS: '..species..' species; '..cases..' full ground-butchering comparisons (mocked PZ engine, real supplied vanilla Lua); exclusion and exception cleanup.')
end
