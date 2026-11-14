# ChilaSeda Save Recovery B42

One-time recovery helper for the Jill save after the yellow KnoxPacks field rucksack disappeared.
On Jill's next player load, it creates a Desert Tan `KnoxPacks.KP_Bag_FieldRuck` at her feet and
fills it from the `Jill_Valantine_12_11_2026_12PM_DEAD` map backup. It does not replace or edit
the lake map chunk.

## Contents recovered from DEAD

| Item | Amount |
| --- | ---: |
| `Base.Plantain` | 4 |
| `Base.Millipede2` | 1 |
| `Base.Termites` | 1 |
| `Base.SilkMothCaterpillar` | 1 |
| `Base.MonarchCaterpillar` | 1 |
| `Base.Egg` | 6 |
| `Base.Pumpkin` | 1 |
| `Base.LargeAnimalBone` | 3 |
| `Base.LetterOpener` | 1 |
| `Base.Pot` | 2 |
| `Base.CarvingFork2` | 1 |
| `Base.TreeBranch2` | 1 |
| `Base.CarBatteryCharger` | 1 |
| `Base.ClosedUmbrellaWhite` | 1 |
| `Base.TorchArmy2` | 1 |
| `Base.Comfrey` | 3 |
| `Base.Hops` | 1 |
| `Base.Rosemary` | 1 |
| `Base.SugarBeet` | 1 |
| `Base.MushroomGeneric3` | 1 |
| `Base.Socks_Long` | 1 |
| `Base.Shoes_TrainerTINT` | 1 |
| `AuthenticZClothing.Dress_Short2` | 1 |
| `Base.Briefs_SmallTrunks_Red` | 1 |
| `Base.Socks_Ankle` | 1 |
| `Base.Trousers_DefaultTEXTURE` | 1 |
| `Base.Vest_DefaultTEXTURE_TINT` | 1 |
| `Base.Shoes_WorkBoots` | 1 |
| `Base.MushroomGeneric7` | 1 |
| `Base.MuttonChop` | 7 |
| `Base.AnimalSinew` | 2 |
| `Base.AMR_Head_Sheep_Icelandic_Ram_V2_ram` | 1 |

## Replacement for the later meat

The later salted items and their exact amounts were not recoverable from the current save or the
DEAD backpack record. To let Chila salt them again, the helper adds raw `Base.ChickenWhole` x1,
`Base.ChickenFoot` x2, `Base.SmallAnimalBone` x5, `Base.Venison` x3, `Base.Steak` x3,
`Base.Beef` x3, `Base.AnimalBone` x6, `Base.LargeAnimalBone` x4 and `Base.Salt` x2. These are
replacement amounts, not a claim that they match the original butchering yield or salting state.

## One-time behavior

The helper marks Jill's character data and the spawned bag so loading the save again will not
create a second recovery bag. After Jill loads, the recovery log entry starts with
`[ChilaSeda_SaveRecovery_B42]`. Keep this local helper enabled until Chila confirms the bag and
contents appeared correctly.

## 1.0.1 recovery fix

Build 42 creates inventory items with the vanilla `instanceItem()` function. The initial helper
used the unavailable `InventoryItemFactory` global, so it could not create the bag and repeated the
same error every tick. Version 1.0.1 uses `instanceItem()` and stops retrying after one creation or
placement failure, avoiding an error flood. The next Jill load still needs to confirm the bag and
contents appear once.
