-- Item-specific local weight targets for vanilla and selected mod items.
-- Definitions are changed after True Weight. Existing accessible instances
-- are rebalanced once per sleep episode when the player has full health.

local TARGET_WEIGHTS = {
    AmmoStrap_Brown_Bullets = 0.40,
    AmmoStrap_Brown_Shells = 0.40,
    AmmoStrap_Bullets = 0.40,
    AmmoStrap_Bullets_308 = 0.40,
    AmmoStrap_Shells = 0.40,
    Clipboard = 0.25,
    Newspaper_Recent = 0.13,
    Magazine_Rich = 0.10,
    MagnifyingGlass = 0.15,
    TissueBox = 0.15,
    TongueDepressorBox = 0.15,
    ToiletBrush = 0.20,
    UmbrellaBlack = 0.60,
    UmbrellaBlue = 0.60,
    UmbrellaRed = 0.60,
    UmbrellaTINTED = 0.60,
    UmbrellaWhite = 0.60,
    KitchenTongs = 0.15,
    Ladle = 0.15,
    PizzaCutter = 0.12,
    Spatula = 0.12,
    TinOpener = 0.15,
    Whisk = 0.10,
    CheeseGrater = 0.30,
    Strainer = 0.30,
    KitchenKnife = 0.20,
    KnifeFillet = 0.10,
    KnifeShiv = 0.15,
    BrokenGlass = 0.05,
    GlassShiv = 0.10,
    Katana_Broken = 0.70,
    Machete = 0.71,
    MacheteBlade_NoTang = 0.48,
    Machete_Crude = 0.71,
    HuntingKnife = 0.25,
    BreadKnife = 0.25,
    Pillow = 0.60,
    Hammer = 0.70,
    HammerForged = 0.70,
    BallPeenHammer = 0.45,
    HammerStone = 1.00,
    Screwdriver = 0.10,
    Screwdriver_Old = 0.10,
    Pliers = 0.15,
    Fork = 0.03,
    Spoon = 0.03,
    WoodenSpoon = 0.03,
    Pot = 0.80,
    PotForged = 0.80,
    Saucepan = 0.50,
    Scissors = 0.10,
    Whetstone = 0.20,
    Stake = 0.25,
    TinOpener_Old = 0.15,
    DuctTape = 0.30,
    Thread = 0.05,
    Thread_Sinew = 0.10,
    Matches = 0.03,
    Lighter = 0.02,
    Rope = 0.50,
    SleepingBag_Cheap_Green_Packed = 2.00,
    SleepingBag_Cheap_Blue_Packed = 2.00,
    SleepingBag_Cheap_Green = 2.00,
    SugarPacket = 0.004,
    Battery = 0.023,
    -- Match ZeroWeightKeys_B42; positive values here are restored after sleep.
    Key1 = 0.0,
    CarKey = 0.0,
    Bandaid = 0.001,
    HandTorch = 0.20,
    WristWatch_Left_DigitalDress = 0.021,
    BluePen = 0.006,
    RedPen = 0.006,
    Pencil = 0.005,
    WaterBottle = 0.05,
    ["22Bullets"] = 0.0035,
    WaterDispenserBottle = 0.80,
    WoodenStick2 = 0.40,
    AnimalBone = 0.175,
    LargeAnimalBone = 0.70,
    SmallAnimalBone = 0.10,
    SharpBoneFragment = 0.01,
    Bowl = 0.50,
    FishingRod = 1.00,
    RubberHose = 0.30,
    PetrolCan = 1.60,
    AlcoholWipes = 0.06,
    BlackSage = 0.05,
    CrushedPepper = 0.05,
    Watermelon = 3.00, HotWaterBottle = 0.40,

    Pillow_Crafted = 0.60, Pillow_Happyface = 0.60, Pillow_Heart = 0.60,
    Pillow_Star = 0.60, MortarPestle = 0.80,
    PepperHabanero = 0.15, PepperHabaneroDried = 0.05,
    PepperJalapeno = 0.15, PepperJalapenoDried = 0.05,
    -- Closely related berries, fruit, forage, and small food items.
    BeautyBerry = 0.05, BerryBlack = 0.05, BerryBlue = 0.05,
    BerryGeneric1 = 0.05, BerryGeneric2 = 0.05, BerryGeneric3 = 0.05,
    BerryGeneric4 = 0.05, BerryGeneric5 = 0.05, BerryPoisonIvy = 0.03,
    HollyBerry = 0.05, WinterBerry = 0.05, Rosehips = 0.05,
    Apple = 0.15, Cherry = 0.05, Grapefruit = 0.20, Grapes = 0.15,
    Lemon = 0.15, Mango = 0.20, Orange = 0.15, Peach = 0.15,
    Pear = 0.15, Pineapple = 0.25, WatermelonSliced = 0.30,
    Dandelions = 0.05, GrapeLeaves = 0.05, LemonGrass = 0.05,
    MintHerb = 0.05, MintHerbDried = 0.03, Ginseng = 0.02, WildGarlic2 = 0.05,
    WildGarlicDried = 0.03,
    -- Salt, pepper, shakers, loose rags, and small containers.
    Pepper = 0.08, Peppercorn = 0.036, Salt = 0.10, SeasoningSalt = 0.10,
    CrushedSalt = 0.05, SaltRock = 0.15, ShakerEmpty = 0.05,
    RippedSheets = 0.05, RippedSheetsDirty = 0.05, AlcoholRippedSheets = 0.10,
    RippedSheetsBundle = 0.80, RippedSheetsDirtyBundle = 0.80,
    RippedSheetsSterilizedBundle = 0.80, DishCloth = 0.20,
    -- Similar bottle, lighter, and packed sleeping bag variants.
    BeerBottle = 0.40, PopBottle = 0.05, PopBottleRare = 0.05,
    LighterDisposable = 0.02, LighterBBQ = 0.05,
    SleepingBag_RedPlaid_Packed = 2.00, SleepingBag_BluePlaid_Packed = 2.00,
    SleepingBag_Green_Packed = 2.00, SleepingBag_GreenPlaid_Packed = 2.00,
    SleepingBag_Camo_Packed = 2.00, SleepingBag_Cheap_Green2_Packed = 2.00,
    SleepingBag_Spiffo_Packed = 2.00, SleepingBag_HighQuality_Brown_Packed = 2.00,
    SleepingBag_Hide_Packed = 3.00,
    Banana = 0.15, Avocado = 0.20, Strewberrie = 0.05,
    WatermelonSmashed = 0.60,
    CommonMallow = 0.05, CommonMallowDried = 0.03,
    Comfrey = 0.05, ComfreyDried = 0.03, Plantain = 0.05, PlantainDried = 0.03,
    String = 0.05, Twine = 0.05, Thread_Aramid = 0.05,
    BallPeenHammerForged = 0.45, ScissorsForged = 0.10,
    Screwdriver_Improvised = 0.10,
    KitchenKnifeForged = 0.20, HuntingKnifeForged = 0.25,
    SteakKnife = 0.10, ButterKnife = 0.03, ButterKnife_Gold = 0.03,
    ButterKnife_Silver = 0.03,
    Fork_Gold = 0.03, Fork_Silver = 0.03, Fork_Bone = 0.03, ForkForged = 0.03,
    Spoon_Gold = 0.03, Spoon_Silver = 0.03, Spoon_Bone = 0.03, SpoonForged = 0.03,
    SaucepanCopper = 0.50, RopeStack = 0.80,
    PepperShaker_Box = 4.00, SaltShaker_Box = 4.00, ShakerEmpty_Box = 4.00,
    -- Rabbit hides and heads are light raw parts, including Animal Remaster variants.
    AMR_Head_Rabbit_Appalachian_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_Appalachian_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_Cottontail_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_Cottontail_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_Dutch_V1_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_Dutch_V1_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_Dutch_V2_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_Dutch_V2_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_Dutch_V3_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_Dutch_V3_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_EnglishSpot_V1_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_EnglishSpot_V1_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_EnglishSpot_V2_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_EnglishSpot_V2_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_EnglishSpot_V3_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_EnglishSpot_V3_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_Harlequin_V1_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_Harlequin_V1_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_Harlequin_V2_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_Harlequin_V2_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_Harlequin_V3_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_Harlequin_V3_Juvenile_rabkitten = 0.10,
    AMR_Head_Rabbit_Swamp_Female_rabdoe = 0.25,
    AMR_Head_Rabbit_Swamp_Juvenile_rabkitten = 0.10,
    AMR_Hide_Rabbit_Appalachian_Female_Full = 0.25,
    AMR_Hide_Rabbit_Appalachian_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Appalachian_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_Appalachian_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_Appalachian_Male_Full = 0.25,
    AMR_Hide_Rabbit_Appalachian_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Cottontail_Female_Full = 0.25,
    AMR_Hide_Rabbit_Cottontail_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Cottontail_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_Cottontail_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_Cottontail_Male_Full = 0.25,
    AMR_Hide_Rabbit_Cottontail_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V1_Female_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V1_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V1_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_Dutch_V1_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_Dutch_V1_Male_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V1_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V2_Female_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V2_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V2_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_Dutch_V2_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_Dutch_V2_Male_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V2_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V3_Female_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V3_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V3_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_Dutch_V3_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_Dutch_V3_Male_Full = 0.25,
    AMR_Hide_Rabbit_Dutch_V3_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V1_Female_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V1_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V1_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_EnglishSpot_V1_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_EnglishSpot_V1_Male_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V1_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V2_Female_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V2_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V2_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_EnglishSpot_V2_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_EnglishSpot_V2_Male_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V2_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V3_Female_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V3_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V3_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_EnglishSpot_V3_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_EnglishSpot_V3_Male_Full = 0.25,
    AMR_Hide_Rabbit_EnglishSpot_V3_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V1_Female_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V1_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V1_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_Harlequin_V1_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_Harlequin_V1_Male_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V1_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V2_Female_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V2_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V2_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_Harlequin_V2_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_Harlequin_V2_Male_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V2_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V3_Female_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V3_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V3_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_Harlequin_V3_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_Harlequin_V3_Male_Full = 0.25,
    AMR_Hide_Rabbit_Harlequin_V3_Male_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Swamp_Female_Full = 0.25,
    AMR_Hide_Rabbit_Swamp_Female_Grey_Full = 0.25,
    AMR_Hide_Rabbit_Swamp_Juvenile_Full = 0.10,
    AMR_Hide_Rabbit_Swamp_Juvenile_Grey_Full = 0.10,
    AMR_Hide_Rabbit_Swamp_Male_Full = 0.25,
    AMR_Hide_Rabbit_Swamp_Male_Grey_Full = 0.25,
    Rabbit_Head_Appalachian = 0.25,
    Rabbit_Head_CottonTail = 0.25,
    Rabbit_Head_Swamp = 0.25,
    Rabbit_Kitten_Head_Appalachian = 0.10,
    Rabbit_Kitten_Head_CottonTail = 0.10,
    Rabbit_Kitten_Head_Swamp = 0.10,
    RabbitLeather_Full = 0.25,
}

local FULL_TYPE_TARGETS = {
    -- Authentic Z upgrade duffels from the documented 1.00 kg targets.
    ["AuthenticZClothing.Bag_DuffelBag_Festive_Tier_1"] = 1.00,
    ["AuthenticZClothing.Bag_DuffelBag_Festive_Tier_2"] = 1.00,
    ["AuthenticZClothing.Bag_DuffelBag_Festive_Tier_3"] = 1.00,
    ["AuthenticZClothing.Bag_DuffelBagGrey_Tier_1"] = 1.00,
    ["AuthenticZClothing.Bag_DuffelBagGrey_Tier_2"] = 1.00,
    ["AuthenticZClothing.Bag_DuffelBagGrey_Tier_3"] = 1.00,
    ["AuthenticZClothing.Bag_MedicalBag_Tier_1"] = 1.00,
    ["AuthenticZClothing.Bag_MedicalBag_Tier_2"] = 1.00,
    ["AuthenticZClothing.Bag_MedicalBag_Tier_3"] = 1.00,
    ["AuthenticZClothing.Bag_Military_Tier_1"] = 1.00,
    ["AuthenticZClothing.Bag_Military_Tier_2"] = 1.00,
    ["AuthenticZClothing.Bag_Military_Tier_3"] = 1.00,
    ["AuthenticZClothing.Bag_Police_Tier_1"] = 1.00,
    ["AuthenticZClothing.Bag_Police_Tier_2"] = 1.00,
    ["AuthenticZClothing.Bag_Police_Tier_3"] = 1.00,
    ["AuthenticZClothing.Bag_Sheriff_Tier_1"] = 1.00,
    ["AuthenticZClothing.Bag_Sheriff_Tier_2"] = 1.00,
    ["AuthenticZClothing.Bag_Sheriff_Tier_3"] = 1.00,
    ["AuthenticZClothing.Bag_SWAT_Tier_1"] = 1.00,
    ["AuthenticZClothing.Bag_SWAT_Tier_2"] = 1.00,
    ["AuthenticZClothing.Bag_SWAT_Tier_3"] = 1.00,
    ["AMRBirds321.PeafowlTrainFeather"] = 0.0022,
    ["ThisIsYourLife.PreservedJournal"] = 0.25,
    ["HomemadeThings.HomemadeHacksaw"] = 0.75,
    ["HomemadeThings.HomemadeNeedle"] = 0.05,
    ["HomemadeThings.HomemadeWoodenMallet"] = 0.60,
    ["HomemadeThings.HomemadeSledgehammer"] = 3.00,
    ["UndeadSurvivor.PrepperKnifeStab"] = 0.20,
    ["HomemadeThings.HomemadeTrowel"] = 0.50,
    ["HomemadeThings.HomemadeGardenSaw"] = 0.60,
    ["HomemadeThings.HomemadePickaxe"] = 2.00,
    ["HomemadeThings.HomemadeScissors"] = 0.20,
    ["HomemadeThings.HomemadeKnittingNeedles"] = 0.10,
    ["HomemadeThings.HomemadeCrudeChisel"] = 0.60,
    ["HomemadeThings.HomemadeFleshingTool"] = 0.60,
    ["HomemadeThings.HomemadeShovel"] = 1.50,
    ["HomemadeThings.HomemadeBucket"] = 0.80,
    ["HomemadeThings.HomemadeSieve_Frame"] = 0.80,
    ["HomemadeThings.HomemadeSieve_Mesh"] = 0.20,
    ["HomemadeThings.HomemadeSieve"] = 1.00,
    ["UndeadSurvivor.PrepperKnifeSwing"] = 0.20,
    ["UndeadSurvivor.PrepperKnifeKnock"] = 0.20,
}

local function targetFor(fullType)
    if type(fullType) ~= "string" then return nil end
    if string.match(fullType, "^Base%.AMR_Hide_Rabbit_") and string.match(fullType, "Juvenile") then
        if string.match(fullType, "_Full$") or string.match(fullType, "_Fur$") then return 0.30 end
        if string.match(fullType, "_Fur_Tan_Wet$") then return 0.27 end
        if string.match(fullType, "_Fur_Tan$") then return 0.16 end
    end    if string.match(fullType, "^Base%.AMR_Hide_Rabbit_")
            and not string.match(fullType, "_Juvenile_") then
        if string.match(fullType, "_Full$") then return 0.43 end
        if string.match(fullType, "_Fur$") then return 0.43 end
        if string.match(fullType, "_Fur_Tan_Wet$") then return 0.384 end
        if string.match(fullType, "_Fur_Tan$") then return 0.225 end
    end
    local exact = FULL_TYPE_TARGETS[fullType]
    if exact then return exact end
    if (string.match(fullType, "^Base%.AMR_Hide_Pig") and string.match(fullType, "_Piglet_")) or string.match(fullType, "^Base%.AMR_Hide_Piglet_") then
        if string.match(fullType, "_Full$") or string.match(fullType, "_Fur$") then
            return 3.75
        end
        if string.match(fullType, "_Fur_Tan_Wet$") then return 3.60 end
        if string.match(fullType, "_Fur_Tan$") then return 1.50 end
    end    if (string.match(fullType, "^Base%.AMR_Hide_Pig_")
            or string.match(fullType, "^Base%.AMR_Hide_Boar_"))
            and not string.match(fullType, "_Piglet_") then
        if string.match(fullType, "_Full$") or string.match(fullType, "_Fur$") then
            return 14.0
        end
        if string.match(fullType, "_Fur_Tan_Wet$") then return 13.6 end
        if string.match(fullType, "_Fur_Tan$") then return 5.6 end
    end
    local sheepLamb = string.match(fullType, "^Base%.AMR_Hide_Sheep_")
            and string.match(fullType, "_Lamb_")
    local lambBreed = sheepLamb and string.match(fullType, "^Base%.AMR_Hide_Sheep_([^_]+)_")
    if string.match(fullType, "^Base%.AMR_Hide_Lamb_") or sheepLamb then
        local lambBaseWeight = lambBreed == "Shetland" and 4.0 or 4.95
        if string.match(fullType, "_Full$") or string.match(fullType, "_Fur$") then
            return lambBaseWeight
        end
        if string.match(fullType, "_Fur_Tan_Wet$") then return lambBaseWeight * 0.8 end
        if string.match(fullType, "_Fur_Tan$") then return lambBaseWeight * 0.4 end
    end
    if string.match(fullType, "^Base%.AMR_Hide_Sheep_")
            and string.match(fullType, "Sheared") then
        if string.match(fullType, "_Full$") or string.match(fullType, "_Fur$") then
            return 2.5
        end
        if string.match(fullType, "_Fur_Tan_Wet$") then return 2.0 end
        if string.match(fullType, "_Fur_Tan$") then return 1.0 end
    end
    local sheepBreed = string.match(fullType, "^Base%.AMR_Hide_Sheep_([^_]+)_")
    local sheepBaseWeight = nil
    if sheepBreed == "Jacob" or sheepBreed == "Dorper" or sheepBreed == "Icelandic" then
        sheepBaseWeight = 6.0
    elseif sheepBreed == "Shetland" then
        sheepBaseWeight = 4.0
    end
    if sheepBaseWeight and not string.match(fullType, "_Lamb_")
            and not string.match(fullType, "Sheared") then
        if string.match(fullType, "_Full$") or string.match(fullType, "_Fur$") then
            return sheepBaseWeight
        end
        if string.match(fullType, "_Fur_Tan_Wet$") then return sheepBaseWeight * 0.8 end
        if string.match(fullType, "_Fur_Tan$") then return sheepBaseWeight * 0.4 end
    end
    if string.match(fullType, "^Base%.AMR_Hide_Cow_")
            or string.match(fullType, "^Base%.AMR_Hide_Bull_") then
        if string.match(fullType, "_Full$") or string.match(fullType, "_Fur$") then
            return 20.0
        end
        if string.match(fullType, "_Fur_Tan_Wet$") then return 16.0 end
        if string.match(fullType, "_Fur_Tan$") then return 8.0 end
    end
    if string.match(fullType, "^Base%.AMR_Hide_Calf_") then
        if string.match(fullType, "_Full$") or string.match(fullType, "_Fur$") then
            return 12.3
        end
        if string.match(fullType, "_Fur_Tan_Wet$") then return 9.84 end
        if string.match(fullType, "_Fur_Tan$") then return 4.92 end
    end
    if string.sub(fullType, 1, 5) == "Base." then
        return TARGET_WEIGHTS[string.sub(fullType, 6)]
    end
    return nil
end

local function usableAnimalType(animalType)
    if type(animalType) == "string" and animalType ~= "" and animalType ~= "none" then
        return animalType
    end
    return nil
end

local function inferAnimalTypeFromName(displayName)
    if type(displayName) ~= "string" then return nil end
    local normalizedName = string.lower(displayName)
    local animals = AnimalDefinitions and AnimalDefinitions.animals
    if animals and type(getText) == "function" then
        for candidate in pairs(animals) do
            local key = "IGUI_AnimalType_" .. candidate
            local ok, translated = pcall(getText, key)
            if ok and type(translated) == "string" and translated ~= key
                    and #translated >= 3
                    and string.find(normalizedName, string.lower(translated), 1, true) then
                return candidate
            end
        end
    end

    local aliases = {
        { "white-tailed buck", "buck" }, { "white tailed buck", "buck" },
        { "venado macho", "buck" }, { "ciervo macho", "buck" }, { "stag", "buck" },
        { "buck", "buck" }, { "cola blanca", "undeaddeerdoe" },
        { "venado", "doe" }, { "venada", "doe" }, { "deer", "doe" },
        { "oveja", "ewe" }, { "sheep", "ewe" }, { "borrego", "ewe" },
        { "cordero", "lamb" }, { "lamb", "lamb" }, { "cabra", "goat" },
        { "cabrito", "goat" }, { "goat", "goat" }, { "conejo", "rabdoe" },
        { "rabbit", "rabdoe" }, { "gallina", "hen" }, { "pollo", "hen" },
        { "chicken", "hen" }, { "pavo", "turkeyhen" }, { "turkey", "turkeyhen" },
        { "becerro", "cowcalf" }, { "ternero", "cowcalf" }, { "calf", "cowcalf" },
        { "vaca", "cow" }, { "cow", "cow" }, { "cerdo", "sow" },
        { "puerco", "sow" }, { "pig", "sow" }, { "raton", "mouse" },
        { "ratón", "mouse" }, { "mouse", "mouse" }, { "rata", "rat" },
        { "rat", "rat" }, { "mapache", "raccoonboar" }, { "raccoon", "raccoonboar" },
    }
    for _, entry in ipairs(aliases) do
        if string.find(normalizedName, entry[1], 1, true) then return entry[2] end
    end
    return nil
end

local function animalDefinitionForType(animalType)
    local animals = AnimalDefinitions and AnimalDefinitions.animals
    if not animals or type(animalType) ~= "string" then return nil end
    local definition = animals[animalType]
    if definition then return definition end
    local stripped = string.gsub(animalType, "^infected", "")
    stripped = string.gsub(stripped, "^undead", "")
    local aliases = {
        rabbit = "rabdoe", deerdoe = "doe", deerstag = "buck", deer = "doe",
        sheep = "ewe", pig = "sow", chicken = "hen", turkey = "turkeyhen",
        calf = "cowcalf",
    }
    return animals[stripped] or animals[aliases[stripped]]
end

local function estimateLiveMass(animalType)
    local definition = animalDefinitionForType(animalType)
    local minimum = definition and tonumber(definition.minWeight)
    local maximum = definition and tonumber(definition.maxWeight)
    if minimum and maximum then return (minimum + maximum) * 0.5 end
    if minimum then return minimum end
    if maximum then return maximum end
    local normalized = string.lower(tostring(animalType or ""))
    normalized = string.gsub(normalized, "^infected", "")
    normalized = string.gsub(normalized, "^undead", "")
    if string.find(normalized, "mouse", 1, true)
            or string.find(normalized, "rat", 1, true) then return 0.5 end
    if string.find(normalized, "rabbit", 1, true)
            or string.find(normalized, "chick", 1, true)
            or string.find(normalized, "quail", 1, true)
            or string.find(normalized, "poult", 1, true) then return 4 end
    if string.find(normalized, "calf", 1, true)
            or string.find(normalized, "lamb", 1, true)
            or string.find(normalized, "piglet", 1, true)
            or string.find(normalized, "fawn", 1, true) then return 50 end
    if string.find(normalized, "cow", 1, true)
            or string.find(normalized, "bull", 1, true)
            or string.find(normalized, "bison", 1, true) then return 500 end
    if string.find(normalized, "turkey", 1, true) then return 10 end
    if string.find(normalized, "deer", 1, true)
            or string.find(normalized, "sheep", 1, true)
            or string.find(normalized, "ewe", 1, true)
            or string.find(normalized, "ram", 1, true)
            or string.find(normalized, "goat", 1, true)
            or string.find(normalized, "pig", 1, true)
            or string.find(normalized, "boar", 1, true) then return 120 end
    return 25
end

local function isSkeletonCorpse(item, body, displayName)
    local function hasSkeletonFlag(object)
        if not object then return false end
        if type(object.isAnimalSkeleton) == "function" then
            local ok, value = pcall(object.isAnimalSkeleton, object)
            if ok and value then return true end
        end
        local ok, modData = pcall(function() return object:getModData() end)
        if ok and modData then
            local flag = modData.skeleton or modData.isSkeleton
            if flag == true or flag == "true" or flag == 1 then return true end
        end
        return false
    end
    if hasSkeletonFlag(body) or hasSkeletonFlag(item) then return true end
    local name = type(displayName) == "string" and string.lower(displayName) or ""
    return string.find(name, "skeleton", 1, true) ~= nil
        or string.find(name, "esqueleto", 1, true) ~= nil
end

local function skeletonWeightTarget(item, animalType)
    local body = nil
    if item and type(item.getDeadBodyObject) == "function" then
        local ok, value = pcall(item.getDeadBodyObject, item)
        if ok then body = value end
    end
    local displayName = nil
    if item and type(item.getDisplayName) == "function" then
        local ok, value = pcall(item.getDisplayName, item)
        if ok then displayName = value end
    end
    if not isSkeletonCorpse(item, body, displayName) then return nil end

    local liveMass = estimateLiveMass(animalType)
    -- Bone mass uses a 16% fraction of the species' midpoint live weight.
    return math.max(0.05, math.floor(liveMass * 0.16 * 20 + 0.5) / 20)
end

local function animalTypeFromData(object)
    if not object or type(object.getModData) ~= "function" then return nil end
    local ok, data = pcall(function() return object:getModData() end)
    if not ok or not data then return nil end
    return usableAnimalType(data.AnimalType or data.animalType)
end

local function corpseAnimalType(item)
    local body = nil
    if type(item.getDeadBodyObject) == "function" then
        local ok
        ok, body = pcall(function() return item:getDeadBodyObject() end)
        if not ok then body = nil end
    end
    if body and type(body.getAnimalType) == "function" then
        local ok, animalType = pcall(function() return body:getAnimalType() end)
        if ok then
            animalType = usableAnimalType(animalType)
            if animalType then return animalType end
        end
    end

    local animalType = animalTypeFromData(body) or animalTypeFromData(item)
    if animalType then return animalType end

    local displayName = nil
    if type(item.getDisplayName) == "function" then
        local ok, value = pcall(function() return item:getDisplayName() end)
        if ok then displayName = value end
    end
    if type(displayName) ~= "string" then return nil end
    animalType = string.match(displayName, "IGUI_AnimalType_([%w_]+)")
    animalType = usableAnimalType(animalType)
    if animalType then return animalType end

    local normalizedName = string.lower(displayName)
    if string.find(normalizedName, "esqueleto", 1, true)
            and string.find(normalizedName, "cola blanca", 1, true) then
        if string.find(normalizedName, "venado", 1, true) then return "undeaddeerstag" end
        return "undeaddeerdoe"
    end
    return inferAnimalTypeFromName(displayName)
end

local function targetForItem(item, fullType)
    if fullType == "Base.Acorn" and item then
        local currentHunger, baseHunger = nil, nil
        if type(item.getHungerChange) == "function" then
            local ok, value = pcall(function() return item:getHungerChange() end)
            if ok then currentHunger = tonumber(value) end
        end
        if type(item.getBaseHunger) == "function" then
            local ok, value = pcall(function() return item:getBaseHunger() end)
            if ok then baseHunger = tonumber(value) end
        end
        if currentHunger and baseHunger and math.abs(baseHunger) > 0.000001 then
            local remaining = math.max(0, math.min(math.abs(currentHunger / baseHunger), 1))
            return 0.0057 * remaining
        end
        return 0.0057
    end
    if fullType == "Base.CorpseAnimal" and item then
        return skeletonWeightTarget(item, corpseAnimalType(item))
    end
    if fullType == "Base.WaterDispenserBottle" and item then
        local fluid = nil
        if type(item.getFluidContainer) == "function" then
            local ok, value = pcall(item.getFluidContainer, item)
            if ok then fluid = value end
        end
        local amount = 0
        if fluid and type(fluid.getAmount) == "function" then
            local ok, value = pcall(fluid.getAmount, fluid)
            if ok then amount = tonumber(value) or 0 end
        end
        return 0.80 + math.max(0, math.min(amount, 15.0))
    end
    if fullType == "Base.PetrolCan" and item then
        local fluid = nil
        if type(item.getFluidContainer) == "function" then
            local ok, value = pcall(item.getFluidContainer, item)
            if ok then fluid = value end
        end
        local amount = 0
        if fluid and type(fluid.getAmount) == "function" then
            local ok, value = pcall(fluid.getAmount, fluid)
            if ok then amount = tonumber(value) or 0 end
        end
        return 1.60 + 0.75 * math.max(0, math.min(amount, 10.0))
    end
    if fullType == "Base.AlcoholWipes" and item then
        local usedDelta = 1
        if type(item.getUsedDelta) == "function" then
            local ok, value = pcall(item.getUsedDelta, item)
            if ok and tonumber(value) then usedDelta = tonumber(value) end
        end
        return 0.01 + 0.05 * math.max(0, math.min(usedDelta, 1))
    end
    return targetFor(fullType)
end

local function scriptItemType(item)
    if item.getFullType then return item:getFullType() end
    if item.getModuleName and item.getName then
        return tostring(item:getModuleName()) .. "." .. tostring(item:getName())
    end
    return nil
end

local function applyItemWeight(item)
    if not item or type(item.getFullType) ~= "function" then return false end
    local target = targetForItem(item, item:getFullType())
    if not target then return false end
    local current = item:getActualWeight()
    if type(current) == "number" and math.abs(current - target) < 0.001 then return false end
    item:setActualWeight(target)
    return true
end

local function rebalanceVanillaItems()
    if not ScriptManager or not ScriptManager.instance then
        print("[ChilaSeda_VanillaWeightFix] ScriptManager unavailable; vanilla weights unchanged")
        return
    end

    local allItems = ScriptManager.instance:getAllItems()
    if not allItems then
        print("[ChilaSeda_VanillaWeightFix] item registry unavailable; vanilla weights unchanged")
        return
    end

    local changed = 0
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item then
            local targetWeight = targetFor(scriptItemType(item))
            if targetWeight then
                item:setActualWeight(targetWeight)
                changed = changed + 1
            end
        end
    end

    print("[ChilaSeda_VanillaWeightFix] adjusted " .. tostring(changed)
        .. " item definition(s) after True Weight key_targets=Base.Key1:0,Base.CarKey:0")
end

local function newKeyRebalanceStats()
    return {
        ["Base.Key1"] = { scanned = 0, updated = 0 },
        ["Base.CarKey"] = { scanned = 0, updated = 0 },
    }
end

local function keyRebalanceSummary(stats)
    stats = stats or newKeyRebalanceStats()
    local parts = {}
    for _, fullType in ipairs({ "Base.Key1", "Base.CarKey" }) do
        local row = stats[fullType] or { scanned = 0, updated = 0 }
        parts[#parts + 1] = fullType .. ":" .. tostring(row.updated) .. "/" .. tostring(row.scanned)
    end
    return table.concat(parts, ",")
end

local function rebalanceContainer(container, visited, keyStats)
    if not container or visited[container] then return 0, 0 end
    visited[container] = true
    local items = container:getItems()
    if not items then return 0, 0 end
    local changed, scanned = 0, 0
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        scanned = scanned + 1
        local fullType = item and type(item.getFullType) == "function" and item:getFullType() or nil
        local keyRow = fullType and keyStats[fullType] or nil
        if keyRow then keyRow.scanned = keyRow.scanned + 1 end
        if applyItemWeight(item) then
            changed = changed + 1
            if keyRow then keyRow.updated = keyRow.updated + 1 end
        end
        if item and item.getInventory then
            local ok, nested = pcall(function() return item:getInventory() end)
            if ok and nested then
                local nestedChanged, nestedScanned = rebalanceContainer(nested, visited, keyStats)
                changed = changed + nestedChanged
                scanned = scanned + nestedScanned
            end
        end
    end
    return changed, scanned
end

local function rebalanceAccessiblePlayer(player, playerNum)
    local keyStats = newKeyRebalanceStats()
    if not player then return 0, 0, keyStats end
    local visited = {}
    local changed, scanned = rebalanceContainer(player:getInventory(), visited, keyStats)
    local paneMenu = rawget(_G, "ISInventoryPaneContextMenu")

    -- Match Weight Monitor's container discovery. Refreshing both pages
    -- populates the nearby container list before getContainers(player).
    playerNum = tonumber(playerNum) or 0
    if type(player.getPlayerNum) == "function" then
        local ok, value = pcall(function() return player:getPlayerNum() end)
        if ok and tonumber(value) then playerNum = tonumber(value) end
    end
    local getInventoryPage = rawget(_G, "getPlayerInventory")
    local getLootPage = rawget(_G, "getPlayerLoot")
    local function refreshBackpackList(getter)
        if type(getter) ~= "function" then return end
        local ok, page = pcall(getter, playerNum)
        if ok and page and page.inventoryPane
            and type(page.refreshBackpacks) == "function" then
            pcall(page.refreshBackpacks, page)
        end
    end
    refreshBackpackList(getInventoryPage)
    refreshBackpackList(getLootPage)

    if paneMenu and paneMenu.getContainers then
        local ok, containers = pcall(function() return paneMenu.getContainers(player) end)
        if ok and containers then
            for i = 0, containers:size() - 1 do
                local containerChanged, containerScanned = rebalanceContainer(containers:get(i), visited, keyStats)
                changed = changed + containerChanged
                scanned = scanned + containerScanned
            end
        end
    end
    return changed, scanned, keyStats
end

local sleepRebalanced = {}
local loadRebalanced = {}
local loadRetryTicks = {}
local loadRetryCount = {}
local loadWaitLogged = {}
local LOAD_RETRY_INTERVAL = 30
local LOAD_RETRY_LIMIT = 20

local function playerIndexFor(player)
    if player and type(player.getPlayerNum) == "function" then
        local ok, value = pcall(function() return player:getPlayerNum() end)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return 0
end

local function onPlayerUpdate(player)
    if not player then return end
    local playerIndex = playerIndexFor(player)
    if not loadRebalanced[playerIndex] then
        local remaining = loadRetryTicks[playerIndex] or 0
        if remaining > 0 then
            loadRetryTicks[playerIndex] = remaining - 1
        else
            loadRetryTicks[playerIndex] = LOAD_RETRY_INTERVAL
            loadRetryCount[playerIndex] = (loadRetryCount[playerIndex] or 0) + 1
            local ok, changed, scanned, keyStats = pcall(rebalanceAccessiblePlayer, player, playerIndex)
            if ok and (scanned or 0) > 0 then
                loadRebalanced[playerIndex] = true
                print("[ChilaSeda_VanillaWeightFix] event=load_rebalance result=complete items="
                    .. tostring(changed or 0) .. " accessible_items=" .. tostring(scanned)
                    .. " attempts=" .. tostring(loadRetryCount[playerIndex])
                    .. " health-independent=true key_instances=" .. keyRebalanceSummary(keyStats))
            elseif ok then
                if not loadWaitLogged[playerIndex] then
                    loadWaitLogged[playerIndex] = true
                    print("[ChilaSeda_VanillaWeightFix] event=load_rebalance result=waiting accessible_items=0")
                end
                if loadRetryCount[playerIndex] >= LOAD_RETRY_LIMIT then
                    loadRebalanced[playerIndex] = true
                    print("[ChilaSeda_VanillaWeightFix] event=load_rebalance result=fallback reason=no-accessible-items retry=limit")
                end
            else
                local reason = tostring(changed or "unknown"):gsub("[\r\n]+", " ")
                if #reason > 180 then reason = string.sub(reason, 1, 180) end
                if loadRetryCount[playerIndex] >= LOAD_RETRY_LIMIT then
                    loadRebalanced[playerIndex] = true
                    print("[ChilaSeda_VanillaWeightFix] event=load_rebalance result=fallback reason="
                        .. reason .. " retry=limit attempts=" .. tostring(loadRetryCount[playerIndex]))
                else
                    print("[ChilaSeda_VanillaWeightFix] event=load_rebalance result=retry reason="
                        .. reason .. " retry_ticks=" .. tostring(LOAD_RETRY_INTERVAL)
                        .. " attempt=" .. tostring(loadRetryCount[playerIndex]))
                end
            end
        end
    end
    if not sleepRebalanced[playerIndex] then return end
    if type(player.isAsleep) ~= "function" then return end

    local ok, asleep = pcall(function() return player:isAsleep() end)
    if ok and not asleep then sleepRebalanced[playerIndex] = nil end
end

local function onSleepingTick(playerIndex)
    playerIndex = tonumber(playerIndex)
    if playerIndex == nil or sleepRebalanced[playerIndex] then return end

    -- Consume this sleep session before any checks so it can never retry while
    -- the player remains asleep, including when health is not at its maximum.
    sleepRebalanced[playerIndex] = true
    local player = getSpecificPlayer and getSpecificPlayer(playerIndex)
    if not player then
        print("[ChilaSeda_VanillaWeightFix] sleep rebalance skipped: player unavailable")
        return
    end

    local ok, health = pcall(function() return player:getHealth() end)
    if not ok or type(health) ~= "number" or health < 100 then
        print("[ChilaSeda_VanillaWeightFix] sleep rebalance skipped: health is not full")
        return
    end

    local changed, scanned, keyStats = rebalanceAccessiblePlayer(player, playerIndex)
    print("[ChilaSeda_VanillaWeightFix] event=sleep_rebalance result=complete items="
        .. tostring(changed or 0) .. " accessible_items=" .. tostring(scanned or 0)
        .. " key_instances=" .. keyRebalanceSummary(keyStats))
end

Events.OnLoadedTileDefinitions.Add(rebalanceVanillaItems)
if Events.OnSleepingTick then Events.OnSleepingTick.Add(onSleepingTick) end
if Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(onPlayerUpdate) end
