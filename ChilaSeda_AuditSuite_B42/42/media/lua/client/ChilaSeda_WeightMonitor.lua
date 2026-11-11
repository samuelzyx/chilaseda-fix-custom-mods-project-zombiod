require "ISUI/ISPanel"

ChilaSedaWeightMonitor = ChilaSedaWeightMonitor or {}
local M = ChilaSedaWeightMonitor
if M.installed then return end
M.installed = true
M.seen = M.seen or {}

local sessionActive = false
local pendingLogLines = {}
local function logLine(message)
    local line = os.date("%Y-%m-%d %H:%M:%S") .. " " .. message
    pendingLogLines[#pendingLogLines + 1] = line
end

local function flushLogLines()
    if not sessionActive or not ChilaWeightLogJ then return false end
    while #pendingLogLines > 0 do
        local ok, result = pcall(ChilaWeightLogJ.append, pendingLogLines[1])
        if not ok or not result then
            print("[ChilaSeda_WeightMonitor] LOG_WRITE_FAILED " .. tostring(ChilaWeightLogJ.lastError()))
            return false
        end
        table.remove(pendingLogLines, 1)
    end
    return true
end

local vanillaTargets = {
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
    KitchenKnife = 0.20, KnifeFillet = 0.10, KnifeShiv = 0.15,
    BrokenGlass = 0.05, GlassShiv = 0.10, Katana_Broken = 0.70,
    Machete = 0.71, MacheteBlade_NoTang = 0.48, Machete_Crude = 0.71,
    HuntingKnife = 0.25, BreadKnife = 0.25,
    Pillow = 0.60,
    Hammer = 0.70, HammerForged = 0.70, BallPeenHammer = 0.45, HammerStone = 1.00,
    Screwdriver = 0.10, Screwdriver_Old = 0.10, Pliers = 0.15,
    Fork = 0.03, Spoon = 0.03, WoodenSpoon = 0.03,
    Pot = 0.80, PotForged = 0.80, Saucepan = 0.50,
    Scissors = 0.10, Whetstone = 0.20, Stake = 0.25, TinOpener_Old = 0.15,
    DuctTape = 0.30, Thread = 0.05, Thread_Sinew = 0.10,
    Matches = 0.03, Lighter = 0.02, Rope = 0.50,
    SleepingBag_Cheap_Green_Packed = 2.00, SleepingBag_Cheap_Blue_Packed = 2.00,
    SleepingBag_Cheap_Green = 2.00,
    SugarPacket = 0.004,
    Battery = 0.023,
    Key1 = 0.009, CarKey = 0.012, Bandaid = 0.001,
    HandTorch = 0.20,
    WristWatch_Left_DigitalDress = 0.021,
    BluePen = 0.006, RedPen = 0.006, Pencil = 0.005,
    WaterBottle = 0.05, WaterDispenserBottle = 0.80, WoodenStick2 = 0.40,
    ["22Bullets"] = 0.0035,
    AnimalBone = 0.175, LargeAnimalBone = 0.70, SmallAnimalBone = 0.10,
    SharpBoneFragment = 0.01, Bowl = 0.50, FishingRod = 1.00, RubberHose = 0.30,
    PetrolCan = 1.60, AlcoholWipes = 0.06, BlackSage = 0.05, CrushedPepper = 0.05,
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
    MintHerb = 0.05, MintHerbDried = 0.03, WildGarlic2 = 0.05,
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

local fullTypeTargets = {
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

-- Variable food/carcass weights are checked as ranges instead of one exact
-- mass. Bounds are documented in docs/Manual_Pesos_B42_y_Monitor.md.
local variableWeightTargets = {
    ["Base.DeadRatSkinned"] = { min = 0.05, max = 0.15 },
    ["Base.Salad"] = { min = 0.15, max = 1.10 },
    ["Base.PotOfStew"] = { min = 3.0, max = 5.0 },
}

local reviewedBaseWeights = {
    ["TOC.Amputation_Foot_L"] = 0.00,
    ["TOC.Amputation_Foot_R"] = 0.00,
    ["TOC.Amputation_ForeArm_L"] = 0.00,
    ["TOC.Amputation_ForeArm_R"] = 0.00,
    ["TOC.Amputation_Hand_L"] = 0.00,
    ["TOC.Amputation_Hand_R"] = 0.00,
    ["TOC.Amputation_LowerLeg_L"] = 0.00,
    ["TOC.Amputation_LowerLeg_R"] = 0.00,
    ["TOC.Amputation_UpperArm_L"] = 0.00,
    ["TOC.Amputation_UpperArm_R"] = 0.00,
    ["TOC.Amputation_UpperLeg_L"] = 0.00,
    ["TOC.Amputation_UpperLeg_R"] = 0.00,
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
    ["AMRBirds321.PeafowlFeather"] = 0.001,
    ["Base.Bandage_Abdomen"] = 0.00,
    ["Base.Bandage_Abdomen_Blood"] = 0.00,
    ["Base.Bandage_Chest"] = 0.00,
    ["Base.Bandage_Chest_Blood"] = 0.00,
    ["Base.Bandage_Groin"] = 0.00,
    ["Base.Bandage_Groin_Blood"] = 0.00,
    ["Base.Bandage_Head"] = 0.00,
    ["Base.Bandage_Head_Blood"] = 0.00,
    ["Base.Bandage_LeftFoot"] = 0.00,
    ["Base.Bandage_LeftFoot_Blood"] = 0.00,
    ["Base.Bandage_LeftHand"] = 0.00,
    ["Base.Bandage_LeftHand_Blood"] = 0.00,
    ["Base.Bandage_LeftLowerArm"] = 0.00,
    ["Base.Bandage_LeftLowerArm_Blood"] = 0.00,
    ["Base.Bandage_LeftLowerLeg"] = 0.00,
    ["Base.Bandage_LeftLowerLeg_Blood"] = 0.00,
    ["Base.Bandage_LeftUpperArm"] = 0.00,
    ["Base.Bandage_LeftUpperArm_Blood"] = 0.00,
    ["Base.Bandage_LeftUpperLeg"] = 0.00,
    ["Base.Bandage_LeftUpperLeg_Blood"] = 0.00,
    ["Base.Bandage_Neck"] = 0.00,
    ["Base.Bandage_Neck_Blood"] = 0.00,
    ["Base.Bandage_RightFoot"] = 0.00,
    ["Base.Bandage_RightFoot_Blood"] = 0.00,
    ["Base.Bandage_RightHand"] = 0.00,
    ["Base.Bandage_RightHand_Blood"] = 0.00,
    ["Base.Bandage_RightLowerArm"] = 0.00,
    ["Base.Bandage_RightLowerArm_Blood"] = 0.00,
    ["Base.Bandage_RightLowerLeg"] = 0.00,
    ["Base.Bandage_RightLowerLeg_Blood"] = 0.00,
    ["Base.Bandage_RightUpperArm"] = 0.00,
    ["Base.Bandage_RightUpperArm_Blood"] = 0.00,
    ["Base.Bandage_RightUpperLeg"] = 0.00,
    ["Base.Bandage_RightUpperLeg_Blood"] = 0.00,
    ["Base.Wound_Abdomen_Bite_Female"] = 0.00,
    ["Base.Wound_Abdomen_Bite_Male"] = 0.00,
    ["Base.Wound_Abdomen_Laceration_Female"] = 0.00,
    ["Base.Wound_Abdomen_Laceration_Male"] = 0.00,
    ["Base.Wound_Abdomen_Scratch_Female"] = 0.00,
    ["Base.Wound_Abdomen_Scratch_Male"] = 0.00,
    ["Base.Wound_Chest_Bite_Female"] = 0.00,
    ["Base.Wound_Chest_Bite_Male"] = 0.00,
    ["Base.Wound_Chest_Laceration_Female"] = 0.00,
    ["Base.Wound_Chest_Laceration_Male"] = 0.00,
    ["Base.Wound_Chest_Scratch_Female"] = 0.00,
    ["Base.Wound_Chest_Scratch_Male"] = 0.00,
    ["Base.Wound_Groin_Bite_Female"] = 0.00,
    ["Base.Wound_Groin_Bite_Male"] = 0.00,
    ["Base.Wound_Groin_Laceration_Female"] = 0.00,
    ["Base.Wound_Groin_Laceration_Male"] = 0.00,
    ["Base.Wound_Groin_Scratch_Female"] = 0.00,
    ["Base.Wound_Groin_Scratch_Male"] = 0.00,
    ["Base.Wound_LForearm_Bite_Female"] = 0.00,
    ["Base.Wound_LForearm_Bite_Male"] = 0.00,
    ["Base.Wound_LForearm_Laceration_Female"] = 0.00,
    ["Base.Wound_LForearm_Laceration_Male"] = 0.00,
    ["Base.Wound_LForearm_Scratch_Female"] = 0.00,
    ["Base.Wound_LForearm_Scratch_Male"] = 0.00,
    ["Base.Wound_LHand_Bite_Female"] = 0.00,
    ["Base.Wound_LHand_Bite_Male"] = 0.00,
    ["Base.Wound_LHand_Laceration_Female"] = 0.00,
    ["Base.Wound_LHand_Laceration_Male"] = 0.00,
    ["Base.Wound_LHand_Scratch_Female"] = 0.00,
    ["Base.Wound_LHand_Scratch_Male"] = 0.00,
    ["Base.Wound_LUArm_Bite_Female"] = 0.00,
    ["Base.Wound_LUArm_Bite_Male"] = 0.00,
    ["Base.Wound_LUArm_Laceration_Female"] = 0.00,
    ["Base.Wound_LUArm_Laceration_Male"] = 0.00,
    ["Base.Wound_LUArm_Scratch_Female"] = 0.00,
    ["Base.Wound_LUArm_Scratch_Male"] = 0.00,
    ["Base.Wound_Neck_Bite_Female"] = 0.00,
    ["Base.Wound_Neck_Bite_Male"] = 0.00,
    ["Base.Wound_Neck_Laceration_Female"] = 0.00,
    ["Base.Wound_Neck_Laceration_Male"] = 0.00,
    ["Base.Wound_Neck_Scratch_Female"] = 0.00,
    ["Base.Wound_Neck_Scratch_Male"] = 0.00,
    ["Base.Wound_RForearm_Bite_Female"] = 0.00,
    ["Base.Wound_RForearm_Bite_Male"] = 0.00,
    ["Base.Wound_RForearm_Laceration_Female"] = 0.00,
    ["Base.Wound_RForearm_Laceration_Male"] = 0.00,
    ["Base.Wound_RForearm_Scratch_Female"] = 0.00,
    ["Base.Wound_RForearm_Scratch_Male"] = 0.00,
    ["Base.Wound_RHand_Bite_Female"] = 0.00,
    ["Base.Wound_RHand_Bite_Male"] = 0.00,
    ["Base.Wound_RHand_Laceration_Female"] = 0.00,
    ["Base.Wound_RHand_Laceration_Male"] = 0.00,
    ["Base.Wound_RHand_Scratch_Female"] = 0.00,
    ["Base.Wound_RHand_Scratch_Male"] = 0.00,
    ["Base.Wound_RUArm_Bite_Female"] = 0.00,
    ["Base.Wound_RUArm_Bite_Male"] = 0.00,
    ["Base.Wound_RUArm_Laceration_Female"] = 0.00,
    ["Base.Wound_RUArm_Laceration_Male"] = 0.00,
    ["Base.Wound_RUArm_Scratch_Female"] = 0.00,
    ["Base.Wound_RUArm_Scratch_Male"] = 0.00,
    ["HunterExpansion.YakPhoneLight"] = 0.00,
    ["TOC.PistolVisual"] = 0.00,
    ["VFECombination.Combination308NoClip_1"] = 0.00,
    ["VFECombination.Combination556M16Magazine_0"] = 0.00,
    ["VFECombination.Combination556M16Magazine_1"] = 0.00,
    ["VFECombination.Combination556M16Magazine_10"] = 0.00,
    ["VFECombination.Combination556M16Magazine_11"] = 0.00,
    ["VFECombination.Combination556M16Magazine_12"] = 0.00,
    ["VFECombination.Combination556M16Magazine_13"] = 0.00,
    ["VFECombination.Combination556M16Magazine_14"] = 0.00,
    ["VFECombination.Combination556M16Magazine_15"] = 0.00,
    ["VFECombination.Combination556M16Magazine_16"] = 0.00,
    ["VFECombination.Combination556M16Magazine_17"] = 0.00,
    ["VFECombination.Combination556M16Magazine_18"] = 0.00,
    ["VFECombination.Combination556M16Magazine_19"] = 0.00,
    ["VFECombination.Combination556M16Magazine_2"] = 0.00,
    ["VFECombination.Combination556M16Magazine_20"] = 0.00,
    ["VFECombination.Combination556M16Magazine_21"] = 0.00,
    ["VFECombination.Combination556M16Magazine_22"] = 0.00,
    ["VFECombination.Combination556M16Magazine_23"] = 0.00,
    ["VFECombination.Combination556M16Magazine_24"] = 0.00,
    ["VFECombination.Combination556M16Magazine_25"] = 0.00,
    ["VFECombination.Combination556M16Magazine_26"] = 0.00,
    ["VFECombination.Combination556M16Magazine_27"] = 0.00,
    ["VFECombination.Combination556M16Magazine_28"] = 0.00,
    ["VFECombination.Combination556M16Magazine_29"] = 0.00,
    ["VFECombination.Combination556M16Magazine_3"] = 0.00,
    ["VFECombination.Combination556M16Magazine_30"] = 0.00,
    ["VFECombination.Combination556M16Magazine_31"] = 0.00,
    ["VFECombination.Combination556M16Magazine_4"] = 0.00,
    ["VFECombination.Combination556M16Magazine_5"] = 0.00,
    ["VFECombination.Combination556M16Magazine_6"] = 0.00,
    ["VFECombination.Combination556M16Magazine_7"] = 0.00,
    ["VFECombination.Combination556M16Magazine_8"] = 0.00,
    ["VFECombination.Combination556M16Magazine_9"] = 0.00,
    ["VFECombination.Combination556M16NoClip_1"] = 0.00,
    ["VFECombination.CombinationM500ShotgunShellNoClip_1"] = 0.00,
    ["VFECombination.CombinationM500ShotgunShellNoClip_2"] = 0.00,
    ["VFECombination.CombinationM500ShotgunShellNoClip_3"] = 0.00,
    ["VFECombination.CombinationM500ShotgunShellNoClip_4"] = 0.00,
    ["VFECombination.CombinationShotgunShellNoClip_1"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_head"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_abrasion_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_head"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_avulsion_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_head"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bandage_torn_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_head"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_bruised_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_abdomen_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_abdomen_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_chest_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_chest_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_foot_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_foot_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_foot_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_foot_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_groin_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_groin_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_hand_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_hand_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_hand_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_hand_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_head_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_head_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_lowerarm_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_lowerarm_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_lowerarm_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_lowerarm_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_lowerleg_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_lowerleg_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_lowerleg_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_lowerleg_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_neck_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_neck_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_upperarm_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_upperarm_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_upperarm_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_upperarm_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_upperleg_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_upperleg_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_upperleg_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_compression_upperleg_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_concussion_head"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_head"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_debris_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_head"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_dirty_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_dislocation_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_dislocation_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_dislocation_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_dislocation_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_dislocation_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_dislocation_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_head"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_mild_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_head"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_moderate_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_head"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_frostbite_severe_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_head"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_inflamed_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_head"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_iodine_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_head"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_maggots_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_head"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_necrotic_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_head"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_over_bandaged_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_head"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_poorly_stitched_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_head"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_puncture_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_head"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_reopened_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_head"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_rinsed_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_head"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_bite_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_head"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_burn_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_head"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_scar_deep_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_sling_upperarm_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_sling_upperarm_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_sling_upperarm_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_sling_upperarm_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_foot_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_foot_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_foot_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_foot_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_hand_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_hand_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_hand_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_hand_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_lowerarm_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_lowerarm_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_lowerarm_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_lowerarm_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_lowerleg_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_lowerleg_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_lowerleg_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_sprain_lowerleg_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_abdomen"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_chest"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_foot_left"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_foot_right"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_groin"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_hand_left"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_hand_right"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_head"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_lowerarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_lowerarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_lowerleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_lowerleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_neck"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_upperarm_left"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_upperarm_right"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_upperleg_left"] = 0.00,
    ["WoundExpansion.WE_Skin_swollen_upperleg_right"] = 0.00,
    ["WoundExpansion.WE_Skin_tourniquet_upperarm_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_tourniquet_upperarm_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_tourniquet_upperarm_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_tourniquet_upperarm_right_male"] = 0.00,
    ["WoundExpansion.WE_Skin_tourniquet_upperleg_left_female"] = 0.00,
    ["WoundExpansion.WE_Skin_tourniquet_upperleg_left_male"] = 0.00,
    ["WoundExpansion.WE_Skin_tourniquet_upperleg_right_female"] = 0.00,
    ["WoundExpansion.WE_Skin_tourniquet_upperleg_right_male"] = 0.00,
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

    if string.sub(fullType, 1, 11) == "DGVPosters." then
        return 0.05
    end

    if string.sub(fullType, 1, 9) == "DGVFlags." then
        local name = string.sub(fullType, 10)
        if string.sub(name, 1, 5) == "Flag_"
            or string.sub(name, 1, 7) == "Banner_" then
            return 0.15
        end
    end

    if string.sub(fullType, 1, 5) == "Base." then
        return vanillaTargets[string.sub(fullType, 6)]
    end
    return fullTypeTargets[fullType]
end

local function safeCall(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local args = { ... }
    local ok, result = pcall(function()
        return object[method](object, unpack(args))
    end)
    if ok then return result end
    return nil
end

local function stackLimitsForItem(item)
    local tetrisLimit = nil
    local tetrisData = rawget(_G, "TetrisItemData")
    if type(tetrisData) == "table" and type(tetrisData.getMaxStackSize) == "function" then
        local ok, value = pcall(tetrisData.getMaxStackSize, item)
        if ok then tetrisLimit = tonumber(value) end
    end

    local scriptItem = safeCall(item, "getScriptItem")
    local scriptLimit = tonumber(safeCall(scriptItem, "getMaxStackSize"))
    return tetrisLimit, scriptLimit
end

local function stackStatus(limit)
    return tonumber(limit) == 100 and "OK" or "REVISAR"
end

local function stackValue(limit)
    return limit ~= nil and tostring(limit) or "sin_dato"
end

local function inferAnimalTypeFromName(displayName)
    if type(displayName) ~= "string" then return nil end
    local normalized = string.lower(displayName)
    local animals = AnimalDefinitions and AnimalDefinitions.animals
    if animals and type(getText) == "function" then
        for candidate in pairs(animals) do
            local key = "IGUI_AnimalType_" .. candidate
            local ok, translated = pcall(getText, key)
            if ok and type(translated) == "string" and translated ~= key
                    and #translated >= 3
                    and string.find(normalized, string.lower(translated), 1, true) then
                return candidate
            end
        end
    end
    local aliases = {
        { "white-tailed buck", "buck" }, { "venado macho", "buck" },
        { "stag", "buck" }, { "buck", "buck" }, { "cola blanca", "undeaddeerdoe" },
        { "venado", "doe" }, { "venada", "doe" }, { "deer", "doe" },
        { "cordero", "lamb" }, { "lamb", "lamb" }, { "oveja", "ewe" },
        { "sheep", "ewe" }, { "borrego", "ewe" }, { "cabra", "goat" },
        { "goat", "goat" }, { "conejo", "rabdoe" }, { "rabbit", "rabdoe" },
        { "gallina", "hen" }, { "pollo", "hen" }, { "chicken", "hen" },
        { "pavo", "turkeyhen" }, { "turkey", "turkeyhen" },
        { "becerro", "cowcalf" }, { "ternero", "cowcalf" }, { "calf", "cowcalf" },
        { "vaca", "cow" }, { "cow", "cow" }, { "cerdo", "sow" },
        { "puerco", "sow" }, { "pig", "sow" }, { "ratÃ³n", "mouse" },
        { "raton", "mouse" }, { "mouse", "mouse" }, { "rata", "rat" },
        { "rat", "rat" }, { "mapache", "raccoonboar" }, { "raccoon", "raccoonboar" },
    }
    for _, alias in ipairs(aliases) do
        if string.find(normalized, alias[1], 1, true) then return alias[2] end
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

local function skeletonWeightTarget(item, animalType)
    local body = safeCall(item, "getDeadBodyObject")
    local bodyData = safeCall(body, "getModData")
    local itemData = safeCall(item, "getModData")
    local displayName = safeCall(item, "getDisplayName")
    local isSkeleton = safeCall(body, "isAnimalSkeleton") == true
        or bodyData and (bodyData.skeleton == true or bodyData.skeleton == "true")
        or itemData and (itemData.skeleton == true or itemData.skeleton == "true")
        or type(displayName) == "string"
            and (string.find(string.lower(displayName), "skeleton", 1, true)
                or string.find(string.lower(displayName), "esqueleto", 1, true))
    if not isSkeleton then return nil end
    local liveMass = estimateLiveMass(animalType)
    return math.max(0.05, math.floor(liveMass * 0.16 * 20 + 0.5) / 20)
end

local function animalTypeForItem(item, fullType)
    if fullType ~= "Base.CorpseAnimal" then return nil end
    local body = safeCall(item, "getDeadBodyObject")
    local animalType = safeCall(body, "getAnimalType")
    if type(animalType) == "string" and animalType ~= "" and animalType ~= "none" then
        return animalType
    end

    local bodyData = safeCall(body, "getModData")
    animalType = bodyData and (bodyData.AnimalType or bodyData.animalType)
    if type(animalType) == "string" and animalType ~= "" and animalType ~= "none" then
        return animalType
    end
    local itemData = safeCall(item, "getModData")
    animalType = itemData and (itemData.AnimalType or itemData.animalType)
    if type(animalType) == "string" and animalType ~= "" and animalType ~= "none" then
        return animalType
    end

    -- Carried skeletons may expose only a key or localized animal name.
    local displayName = safeCall(item, "getDisplayName")
    if type(displayName) == "string" then
        animalType = string.match(displayName, "IGUI_AnimalType_([%w_]+)")
        if animalType then return animalType end
        local normalizedName = string.lower(displayName)
        if string.find(normalizedName, "esqueleto", 1, true)
                and string.find(normalizedName, "cola blanca", 1, true) then
            if string.find(normalizedName, "venado", 1, true) then return "undeaddeerstag" end
            return "undeaddeerdoe"
        end
        return inferAnimalTypeFromName(displayName)
    end
    return nil
end

local function targetForItem(item, fullType, animalType)
    if fullType == "Base.Acorn" and item then
        local currentHunger = tonumber(safeCall(item, "getHungerChange"))
        local baseHunger = tonumber(safeCall(item, "getBaseHunger"))
        if currentHunger and baseHunger and math.abs(baseHunger) > 0.000001 then
            local remaining = math.max(0, math.min(math.abs(currentHunger / baseHunger), 1))
            return 0.0057 * remaining
        end
        return 0.0057
    end
    if fullType == "Base.CorpseAnimal" and animalType then
        return skeletonWeightTarget(item, animalType)
    end
    if fullType == "Base.WaterDispenserBottle" and item then
        local fluid = safeCall(item, "getFluidContainer")
        local amount = tonumber(safeCall(fluid, "getAmount")) or 0
        return 0.80 + math.max(0, math.min(amount, 15.0))
    end
    if fullType == "Base.PetrolCan" and item then
        local fluid = safeCall(item, "getFluidContainer")
        local amount = tonumber(safeCall(fluid, "getAmount")) or 0
        return 1.60 + 0.75 * math.max(0, math.min(amount, 10.0))
    end
    if fullType == "Base.AlcoholWipes" and item then
        local usedDelta = tonumber(safeCall(item, "getUsedDelta")) or 1
        return 0.01 + 0.05 * math.max(0, math.min(usedDelta, 1))
    end
    return targetFor(fullType)
end

local function animalTypeName(animalType)
    if not animalType then return nil end
    local baseType = string.gsub(animalType, "^infected", "")
    baseType = string.gsub(baseType, "^undead", "")
    local aliases = { deerdoe = "doe", deerstag = "buck", deer = "doe",
        rabbit = "rabdoe", sheep = "ewe", pig = "sow", chicken = "hen",
        calf = "cowcalf", turkey = "turkeyhen" }
    baseType = aliases[baseType] or baseType
    local key = "IGUI_AnimalType_" .. baseType
    if type(getText) == "function" then
        local ok, value = pcall(getText, key)
        if ok and type(value) == "string" and value ~= key then return value end
    end
    return nil
end

local function collectContainer(container, current, visited, source)
    if not container then return false end
    if visited[container] then return true end
    visited[container] = true
    source = source or "ubicacion_desconocida"

    local items = safeCall(container, "getItems")
    local size = tonumber(safeCall(items, "size"))
    if not size then return false end
    for i = 0, size - 1 do
        local item = safeCall(items, "get", i)
        if not item then return false end
        local fullType = safeCall(item, "getFullType")
        if type(fullType) ~= "string" then return false end
        local animalType = animalTypeForItem(item, fullType)
        local target = targetForItem(item, fullType, animalType)
        local targetRange = variableWeightTargets[fullType]
        local actual = tonumber(safeCall(item, "getActualWeight"))
        local count = tonumber(safeCall(item, "getCount")) or 1
        local tetrisLimit, scriptLimit = stackLimitsForItem(item)
        local displayName = animalTypeName(animalType)
            or safeCall(item, "getDisplayName") or fullType
        local quantity = math.max(1, count)
        local itemKey = animalType and (fullType .. "|" .. animalType) or fullType
        local rowKey = itemKey .. "|source=" .. tostring(source)
        local row = current[rowKey]
        if not row then
            row = {
                fullType = fullType, animalType = animalType,
                animalTypeName = animalTypeName(animalType),
                expected = target,
                targetMin = targetRange and targetRange.min or nil,
                targetMax = targetRange and targetRange.max or nil,
                actual = actual,
                name = tostring(displayName), count = 0, totalWeight = 0,
                minActual = nil, maxActual = nil, sourceCounts = {},
                minTetrisLimit = nil, maxTetrisLimit = nil, unknownTetrisLimit = 0,
                minScriptLimit = nil, maxScriptLimit = nil,
            }
            current[rowKey] = row
        end
        row.count = row.count + quantity
        row.sourceCounts[source] = (row.sourceCounts[source] or 0) + quantity
        if tetrisLimit then
            row.minTetrisLimit = row.minTetrisLimit
                and math.min(row.minTetrisLimit, tetrisLimit) or tetrisLimit
            row.maxTetrisLimit = row.maxTetrisLimit
                and math.max(row.maxTetrisLimit, tetrisLimit) or tetrisLimit
        else
            row.unknownTetrisLimit = row.unknownTetrisLimit + quantity
        end
        if scriptLimit then
            row.minScriptLimit = row.minScriptLimit
                and math.min(row.minScriptLimit, scriptLimit) or scriptLimit
            row.maxScriptLimit = row.maxScriptLimit
                and math.max(row.maxScriptLimit, scriptLimit) or scriptLimit
        end
        if actual then
            row.actual = actual
            row.totalWeight = row.totalWeight + actual * quantity
            row.minActual = row.minActual and math.min(row.minActual, actual) or actual
            row.maxActual = row.maxActual and math.max(row.maxActual, actual) or actual
        end

        local isContainer = false
        if type(instanceof) == "function" then
            local ok, result = pcall(instanceof, item, "InventoryContainer")
            isContainer = ok and result or false
        end
        if isContainer then
            local bagName = safeCall(item, "getDisplayName") or safeCall(item, "getFullType") or "bolsa"
            local bagInventory = safeCall(item, "getInventory")
            if not collectContainer(bagInventory, current, visited,
                    source .. "/mochila:" .. tostring(bagName)) then
                return false
            end
        end
    end
    return true
end

local function nearbyContainerSource(container, index)
    local containerType = tostring(safeCall(container, "getType") or "desconocido")
    local parent = safeCall(container, "getParent")
    -- B42 ItemContainer:getCustomName() dereferences its parent internally.
    -- Nearby lists can include detached containers whose parent is nil.
    local name = parent and (safeCall(container, "getCustomName")
        or safeCall(parent, "getName")
        or safeCall(parent, "getObjectName")) or nil
    name = name or containerType
    local square = safeCall(parent, "getSquare")
    local x = safeCall(square, "getX")
    local y = safeCall(square, "getY")
    local z = safeCall(square, "getZ")
    local location = x and y and z
        and (tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)) or "sin_coordenadas"
    return "cercano[" .. tostring(index) .. "]:" .. containerType .. ":"
        .. tostring(name) .. "@" .. location
end

local function scanState(message)
    if M.lastScanState ~= message then
        logLine("SCAN_STATUS " .. message)
        M.lastScanState = message
    end
end

local function scanPlayer()
    local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
    local inventory = safeCall(player, "getInventory")
    if not player then scanState("BLOCKED reason=player_unavailable"); return false end
    if not inventory then scanState("BLOCKED reason=player_inventory_unavailable"); return false end

    local playerNum = tonumber(safeCall(player, "getPlayerNum")) or 0
    local getInventoryPage = rawget(_G, "getPlayerInventory")
    local getLootPage = rawget(_G, "getPlayerLoot")
    if type(getInventoryPage) ~= "function" or type(getLootPage) ~= "function" then
        scanState("BLOCKED reason=inventory_page_api_unavailable")
        return false
    end
    local okInventoryPage, inventoryPage = pcall(getInventoryPage, playerNum)
    local okLootPage, lootPage = pcall(getLootPage, playerNum)
    if not okInventoryPage or not okLootPage or not inventoryPage or not lootPage then
        scanState("BLOCKED reason=inventory_pages_unavailable")
        return false
    end

    local pages = {}
    pages[#pages + 1] = inventoryPage
    pages[#pages + 1] = lootPage
    for _, page in ipairs(pages) do
        if not page.inventoryPane or type(page.refreshBackpacks) ~= "function" then
            scanState("BLOCKED reason=container_refresh_unavailable")
            return false
        end
        do
            local ok = pcall(page.refreshBackpacks, page)
            if not ok then
                scanState("BLOCKED reason=container_refresh_failed")
                return false
            end
        end
    end

    local current = {}
    local visited = {}
    if not collectContainer(inventory, current, visited, "inventario_principal") then
        scanState("BLOCKED reason=player_inventory_scan_failed")
        return false
    end
    local paneMenu = rawget(_G, "ISInventoryPaneContextMenu")
    if not paneMenu or type(paneMenu.getContainers) ~= "function" then
        scanState("BLOCKED reason=nearby_container_api_unavailable")
        return false
    end
    local okContainers, containers = pcall(paneMenu.getContainers, player)
    if not okContainers or not containers then
        scanState("BLOCKED reason=nearby_container_list_unavailable")
        return false
    end
    local nearbyCount = tonumber(safeCall(containers, "size"))
    if not nearbyCount then
        scanState("BLOCKED reason=nearby_container_count_unavailable")
        return false
    end
    for i = 0, nearbyCount - 1 do
        local container = safeCall(containers, "get", i)
        if not collectContainer(container, current, visited, nearbyContainerSource(container, i + 1)) then
            scanState("BLOCKED reason=nearby_container_scan_failed index=" .. tostring(i + 1))
            return false
        end
    end
    scanState("OK inventory=ok nearby=ok refreshed=ok nearbyContainers=" .. tostring(nearbyCount))

    local wasAccessible = {}
    for fullType, row in pairs(M.seen) do
        wasAccessible[fullType] = (tonumber(row.currentCount) or 0) > 0
        row.currentCount = 0
    end
    for rowKey, currentRow in pairs(current) do
        local row = M.seen[rowKey]
        local isNew = row == nil
        if not row then
            row = { firstSeen = os.date("%H:%M") }
            M.seen[rowKey] = row
        end
        row.fullType = currentRow.fullType
        row.animalType = currentRow.animalType
        row.name = currentRow.name
        row.expected = currentRow.expected
        row.targetMin = currentRow.targetMin
        row.targetMax = currentRow.targetMax
        row.actual = currentRow.actual
        row.totalWeight = currentRow.totalWeight
        row.tetrisStackLimit = currentRow.minTetrisLimit == currentRow.maxTetrisLimit
            and currentRow.unknownTetrisLimit == 0 and currentRow.minTetrisLimit or nil
        row.scriptStackLimit = currentRow.minScriptLimit == currentRow.maxScriptLimit
            and currentRow.minScriptLimit or nil
        row.stackStatus = row.tetrisStackLimit == 100 and "OK" or "REVISAR"
        row.currentCount = currentRow.count
        row.lastSeen = os.date("%H:%M")
        local status = "REVISAR"
        if currentRow.expected and currentRow.minActual then
            status = math.abs(currentRow.minActual - currentRow.expected) <= 0.005
                and math.abs(currentRow.maxActual - currentRow.expected) <= 0.005
                and "OK" or "REVISAR"
        elseif currentRow.targetMin and currentRow.minActual then
            status = currentRow.minActual >= currentRow.targetMin - 0.005
                and currentRow.maxActual <= currentRow.targetMax + 0.005
                and "OK" or "REVISAR"
        end
        local actualChanged = row.lastLoggedActual == nil and currentRow.actual ~= nil
            or row.lastLoggedActual ~= nil and currentRow.actual == nil
            or row.lastLoggedActual ~= nil and currentRow.actual ~= nil
                and math.abs(row.lastLoggedActual - currentRow.actual) > 0.005
        local countChanged = row.lastLoggedCount ~= currentRow.count
        local totalChanged = row.lastLoggedTotalWeight == nil
            or math.abs(row.lastLoggedTotalWeight - currentRow.totalWeight) > 0.005
        local sourceList = {}
        for sourceName in pairs(currentRow.sourceCounts) do sourceList[#sourceList + 1] = sourceName end
        table.sort(sourceList)
        local sources = table.concat(sourceList, ",")
        local sourcesChanged = row.lastLoggedSources ~= sources
        local nameChanged = row.lastLoggedName ~= currentRow.name
        local tetrisStackChanged = row.lastLoggedTetrisStackLimit ~= row.tetrisStackLimit
        local scriptStackChanged = row.lastLoggedScriptStackLimit ~= row.scriptStackLimit
        if isNew or row.lastLoggedStatus ~= status or actualChanged or countChanged
                or totalChanged or sourcesChanged or nameChanged
                or tetrisStackChanged or scriptStackChanged then
            logLine(status .. " type=" .. tostring(currentRow.fullType)
                .. " name=" .. string.format("%q", tostring(currentRow.name))
                .. " animalType=" .. tostring(currentRow.animalType or "none")
                .. " actual=" .. tostring(currentRow.actual)
                .. " totalWeight=" .. string.format("%.3f", currentRow.totalWeight)
                .. " target=" .. (currentRow.expected and tostring(currentRow.expected) or "sin_meta")
                .. (currentRow.targetMin and (" targetRange=" .. tostring(currentRow.targetMin)
                    .. ".." .. tostring(currentRow.targetMax)) or "")
                .. " count=" .. tostring(currentRow.count)
                .. " tetrisStack=" .. stackValue(row.tetrisStackLimit)
                .. " scriptStack=" .. stackValue(row.scriptStackLimit)
                .. " stackStatus=" .. tostring(row.stackStatus)
                .. " sources=" .. string.format("%q", sources))
            row.lastLoggedStatus = status
            row.lastLoggedActual = currentRow.actual
            row.lastLoggedCount = currentRow.count
            row.lastLoggedTotalWeight = currentRow.totalWeight
            row.lastLoggedSources = sources
            row.lastLoggedName = currentRow.name
            row.lastLoggedTetrisStackLimit = row.tetrisStackLimit
            row.lastLoggedScriptStackLimit = row.scriptStackLimit
        end
    end
    for rowKey, row in pairs(M.seen) do
        if wasAccessible[rowKey] and row.currentCount == 0
                and row.lastLoggedStatus ~= "Visto" then
            logLine("Visto type=" .. tostring(row.fullType)
                .. " animalType=" .. tostring(row.animalType or "none")
                .. " actual=" .. tostring(row.actual)
                .. " target=" .. (row.expected and tostring(row.expected) or "sin_meta")
                .. (row.targetMin and (" targetRange=" .. tostring(row.targetMin)
                    .. ".." .. tostring(row.targetMax)) or "")
                .. " tetrisStack=" .. stackValue(row.tetrisStackLimit)
                .. " scriptStack=" .. stackValue(row.scriptStackLimit)
                .. " stackStatus=" .. tostring(row.stackStatus or "REVISAR")
                .. " count=0")
            row.lastLoggedStatus = "Visto"
        end
    end

    if M.panel then
        M.panel.rows = {}
        for _, row in pairs(M.seen) do M.panel.rows[#M.panel.rows + 1] = row end
        table.sort(M.panel.rows, function(a, b)
            if a.currentCount ~= b.currentCount then return a.currentCount > b.currentCount end
            return tostring(a.name) < tostring(b.name)
        end)
        local maxPage = math.max(1, math.ceil(#M.panel.rows / M.panel.rowsPerPage))
        M.panel.page = math.min(M.panel.page, maxPage)
    end
end

local WeightPanel = ISPanel:derive("ChilaSedaWeightMonitorPanel")

function WeightPanel:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.rows = {}
    o.page = 1
    o.rowsPerPage = 18
    o.backgroundColor = { r = 0.06, g = 0.08, b = 0.10, a = 0.96 }
    o.borderColor = { r = 0.32, g = 0.64, b = 0.70, a = 1 }
    return o
end

function WeightPanel:prerender()
    self:drawRect(0, 0, self.width, self.height, 0.96, 0.06, 0.08, 0.10)
    self:drawRectBorder(0, 0, self.width, self.height, 1, 0.32, 0.64, 0.70)
end

function WeightPanel:render()
    local small = UIFont.Small
    local white = { 0.90, 0.93, 0.95 }
    self:drawText("Monitor de peso de objetos", 18, 12, 0.35, 0.88, 0.88, 1, UIFont.Medium)
    self:drawText("Ctrl+Shift+F7 cierra el monitor. Incluye mochilas y contenedores abiertos.",
        18, 34, 0.72, 0.78, 0.82, 1, small)
    self:drawText("X", self.width - 30, 12, 0.95, 0.70, 0.70, 1, UIFont.Medium)

    local headerY = 68
    self:drawRect(12, headerY, self.width - 24, 24, 0.85, 0.13, 0.19, 0.22)
    self:drawText("Objeto", 20, headerY + 4, white[1], white[2], white[3], 1, small)
    self:drawText("Tipo", 230, headerY + 4, white[1], white[2], white[3], 1, small)
    self:drawText("Accesibles", 490, headerY + 4, white[1], white[2], white[3], 1, small)
    self:drawText("Real kg", 560, headerY + 4, white[1], white[2], white[3], 1, small)
    self:drawText("Objetivo", 640, headerY + 4, white[1], white[2], white[3], 1, small)
    self:drawText("Limite", 730, headerY + 4, white[1], white[2], white[3], 1, small)
    self:drawText("Peso", 800, headerY + 4, white[1], white[2], white[3], 1, small)
    self:drawText("Estado", 870, headerY + 4, white[1], white[2], white[3], 1, small)

    if #self.rows == 0 then
        self:drawText("No hay objetos en el inventario ni en contenedores accesibles.",
            20, headerY + 48, 0.80, 0.84, 0.86, 1, small)
    else
        local first = (self.page - 1) * self.rowsPerPage + 1
        local last = math.min(#self.rows, first + self.rowsPerPage - 1)
        local y = headerY + 30
        for index = first, last do
            local row = self.rows[index]
            if (index - first) % 2 == 1 then
                self:drawRect(12, y - 2, self.width - 24, 22, 0.35, 0.14, 0.18, 0.20)
            end
            local state, r, g, b = "Visto", 0.76, 0.79, 0.82
            if row.currentCount > 0 then
                if row.expected and row.actual
                        and math.abs(row.actual - row.expected) <= 0.005 then
                    state, r, g, b = "OK", 0.32, 0.94, 0.48
                elseif row.targetMin and row.actual
                        and row.actual >= row.targetMin - 0.005
                        and row.actual <= row.targetMax + 0.005 then
                    state, r, g, b = "OK", 0.32, 0.94, 0.48
                else
                    state, r, g, b = "REVISAR", 1.0, 0.36, 0.30
                end
            end
            self:drawText(tostring(row.name), 20, y, 0.90, 0.92, 0.94, 1, small)
            local typeLabel = row.animalTypeName or row.fullType
            self:drawText(tostring(typeLabel), 230, y, 0.70, 0.75, 0.78, 1, small)
            self:drawText(tostring(row.currentCount or 0), 490, y, 0.90, 0.92, 0.94, 1, small)
            self:drawText(row.actual and string.format("%.3f", row.actual) or "Ã¢â‚¬â€", 560, y, 0.90, 0.92, 0.94, 1, small)
            local targetLabel = row.expected and string.format("%.3f", row.expected)
                or row.targetMin and string.format("%.2f–%.2f", row.targetMin, row.targetMax)
                or "sin meta"
            self:drawText(targetLabel,
                640, y, 0.90, 0.92, 0.94, 1, small)
            local stackColor = row.stackStatus == "OK" and 0.32 or 1.0
            local stackGreen = row.stackStatus == "OK" and 0.94 or 0.36
            local stackBlue = row.stackStatus == "OK" and 0.48 or 0.30
            self:drawText(row.tetrisStackLimit and tostring(row.tetrisStackLimit) or "sin dato",
                730, y, stackColor, stackGreen, stackBlue, 1, small)
            self:drawText(state, 800, y, r, g, b, 1, small)
            self:drawText(row.stackStatus or "REVISAR", 870, y, stackColor, stackGreen, stackBlue, 1, small)
            y = y + 24
        end
    end

    local pageCount = math.max(1, math.ceil(#self.rows / self.rowsPerPage))
    self:drawText("Ã¢â‚¬Â¹ Anterior", 20, self.height - 32, 0.70, 0.88, 0.92, 1, small)
    self:drawText("PÃƒÂ¡gina " .. tostring(self.page) .. " / " .. tostring(pageCount),
        self.width / 2 - 45, self.height - 32, 0.80, 0.84, 0.86, 1, small)
    self:drawText("Siguiente Ã¢â‚¬Âº", self.width - 120, self.height - 32, 0.70, 0.88, 0.92, 1, small)
    self:drawText("Stack muestra el lÃ­mite efectivo de Tetris; REVISAR indica lÃ­mite distinto de 100 o sin lectura.",
        20, self.height - 58, 0.68, 0.73, 0.77, 1, small)
end

function WeightPanel:onMouseDown(x, y)
    if y < 44 and x >= self.width - 48 then
        if M.panel then M.panel:removeFromUIManager(); M.panel = nil end
        return true
    end
    if y >= self.height - 42 then
        local pageCount = math.max(1, math.ceil(#self.rows / self.rowsPerPage))
        if x < 140 then self.page = math.max(1, self.page - 1) end
        if x > self.width - 140 then self.page = math.min(pageCount, self.page + 1) end
        return true
    end
    return ISPanel.onMouseDown(self, x, y)
end

local function togglePanel()
    if M.panel then
        M.panel:removeFromUIManager()
        M.panel = nil
        return
    end

    local core = getCore()
    local screenWidth = core:getScreenWidth()
    local screenHeight = core:getScreenHeight()
    local width, height = math.min(960, screenWidth - 40), math.min(600, screenHeight - 40)
    local x, y = math.floor((screenWidth - width) / 2), math.floor((screenHeight - height) / 2)
    M.panel = WeightPanel:new(x, y, width, height)
    M.panel:initialise()
    M.panel:addToUIManager()
    M.panel:setAlwaysOnTop(true)
    M.panel:bringToTop()
    scanPlayer()
end

local function onKeyPressed(key)
    if not ChilaWeightLogJ then return end
    if key ~= Keyboard.KEY_F7 then return end
    if not (Keyboard.isKeyDown(Keyboard.KEY_LCONTROL) or Keyboard.isKeyDown(Keyboard.KEY_RCONTROL)) then return end
    if not (Keyboard.isKeyDown(Keyboard.KEY_LSHIFT) or Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)) then return end
    togglePanel()
end

local function emitStackCatalogPart(catalog)
    if #catalog.entries == 0 then return end
    catalog.part = catalog.part + 1
    logLine("STACK_CATALOG_PART part=" .. tostring(catalog.part)
        .. " entries=" .. string.format("%q", table.concat(catalog.entries, ";")))
    catalog.entries = {}
end

local function emitWeightCatalogPart(catalog)
    if #catalog.weightEntries == 0 then return end
    logLine("WEIGHT_CATALOG_PART part=" .. tostring(catalog.part)
        .. " entries=" .. string.format("%q", table.concat(catalog.weightEntries, ";")))
    catalog.weightEntries = {}
end

local function startStackCatalog()
    local tetrisData = rawget(_G, "TetrisItemData")
    if type(tetrisData) ~= "table"
            or type(tetrisData.getItemDefinitonByItemScript) ~= "function" then
        logLine("STACK_CATALOG_BLOCKED reason=tetris_item_data_unavailable")
        return
    end

    local scriptManagerClass = rawget(_G, "ScriptManager")
    local scriptManager = scriptManagerClass and scriptManagerClass.instance
    local definitions = safeCall(scriptManager, "getAllItems")
    local total = tonumber(safeCall(definitions, "size"))
    if not total then
        logLine("STACK_CATALOG_BLOCKED reason=script_item_catalog_unavailable")
        return
    end

    M.stackCatalog = {
        definitions = definitions,
        total = total,
        cursor = 0,
        checked = 0,
        ok = 0,
        review = 0,
        part = 0,
        entries = {},
        weightEntries = {},
        weightMapped = 0,
        weightDynamic = 0,
        weightUnmapped = 0,
        weightBaseOK = 0,
        weightReviewMismatch = 0,
    }
    logLine("STACK_CATALOG_START target=100 definitions=" .. tostring(total) .. " batch=8")
    logLine("WEIGHT_CATALOG_START definitions=" .. tostring(total)
        .. " batch=8 fields=fullType,scriptWeight,scriptActualWeight,target,coverage")
end

local function scanStackCatalogBatch()
    local catalog = M.stackCatalog
    if not catalog then return end
    local tetrisData = rawget(_G, "TetrisItemData")
    if type(tetrisData) ~= "table"
            or type(tetrisData.getItemDefinitonByItemScript) ~= "function" then
        logLine("STACK_CATALOG_BLOCKED reason=tetris_item_data_lost")
        M.stackCatalog = nil
        return
    end

    local stop = math.min(catalog.total, catalog.cursor + 8)
    for index = catalog.cursor, stop - 1 do
        local scriptItem = safeCall(catalog.definitions, "get", index)
        local fullType = scriptItem and safeCall(scriptItem, "getFullName") or nil
        local ok, data = false, nil
        if scriptItem then
            ok, data = pcall(tetrisData.getItemDefinitonByItemScript, scriptItem, false)
        end
        local stackLimit = ok and type(data) == "table"
            and tonumber(data.maxStackSize) or nil
        local scriptLimit = scriptItem
            and tonumber(safeCall(scriptItem, "getMaxStackSize")) or nil
        local status = stackStatus(stackLimit)
        if stackLimit == 100 then
            catalog.ok = catalog.ok + 1
        else
            catalog.review = catalog.review + 1
        end
        catalog.checked = catalog.checked + 1
        catalog.entries[#catalog.entries + 1] = tostring(fullType or ("unknown_" .. tostring(index)))
            .. "," .. stackValue(stackLimit) .. "," .. stackValue(scriptLimit) .. "," .. status
        local scriptWeight = scriptItem and tonumber(safeCall(scriptItem, "getWeight")) or nil
        local scriptActualWeight = scriptItem
            and tonumber(safeCall(scriptItem, "getActualWeight")) or nil
        local weightTarget = targetFor(fullType)
        local coverage = weightTarget and "MAPPED" or "UNMAPPED"
        if fullType == "Base.Acorn" or fullType == "Base.CorpseAnimal" or fullType == "Base.WaterDispenserBottle"
                or fullType == "Base.PetrolCan" or fullType == "Base.AlcoholWipes" then
            coverage = "DYNAMIC"
            catalog.weightDynamic = catalog.weightDynamic + 1
        elseif weightTarget then
            catalog.weightMapped = catalog.weightMapped + 1
        elseif reviewedBaseWeights[fullType] ~= nil then
            if scriptActualWeight
                    and math.abs(scriptActualWeight - reviewedBaseWeights[fullType]) < 0.001 then
                coverage = "BASE_OK"
                catalog.weightBaseOK = catalog.weightBaseOK + 1
            else
                coverage = "REVIEW_MISMATCH"
                catalog.weightReviewMismatch = catalog.weightReviewMismatch + 1
            end
        else
            catalog.weightUnmapped = catalog.weightUnmapped + 1
        end
        catalog.weightEntries[#catalog.weightEntries + 1] = tostring(fullType or "unknown")
            .. "," .. stackValue(scriptWeight) .. "," .. stackValue(scriptActualWeight)
            .. "," .. stackValue(weightTarget) .. "," .. coverage
        if #catalog.weightEntries >= 32 then emitWeightCatalogPart(catalog) end
        if #catalog.entries >= 32 then emitStackCatalogPart(catalog) end
    end
    catalog.cursor = stop

    if catalog.cursor >= catalog.total then
        emitStackCatalogPart(catalog)
        emitWeightCatalogPart(catalog)
        logLine("STACK_CATALOG_END checked=" .. tostring(catalog.checked)
            .. " ok=" .. tostring(catalog.ok)
            .. " revisar=" .. tostring(catalog.review)
            .. " target=100")
        logLine("WEIGHT_CATALOG_END checked=" .. tostring(catalog.checked)
            .. " mapped=" .. tostring(catalog.weightMapped)
            .. " dynamic=" .. tostring(catalog.weightDynamic)
            .. " base_ok=" .. tostring(catalog.weightBaseOK)
            .. " review_mismatch=" .. tostring(catalog.weightReviewMismatch)
            .. " unmapped=" .. tostring(catalog.weightUnmapped))
        M.stackCatalog = nil
    end
end

local tickCount = 0
local function onTick()
    if not sessionActive then return end
    if M.stackCatalog then
        scanStackCatalogBatch()
    end
    tickCount = tickCount + 1
    local interval = M.panel and 30 or 120
    if tickCount < interval then return end
    tickCount = 0
    scanPlayer()
    flushLogLines()
end

local function onGameStart()
    if not ChilaWeightLogJ then
        print("[ChilaSeda_WeightMonitor] Java log bridge unavailable; session log cannot be created")
        return
    end
    local ok, path = pcall(ChilaWeightLogJ.beginGame)
    if not ok or not path or path == "" then
        print("[ChilaSeda_WeightMonitor] SESSION_START_FAILED " .. tostring(ChilaWeightLogJ.lastError()))
        return
    end
    sessionActive = true
    logLine("SESSION_START version=1.9.8 autoScan=true intervalTicks=120 stackAudit=true weightCatalog=true file=" .. tostring(path))
    startStackCatalog()
    flushLogLines()
end

local function onMainMenuEnter()
    if not sessionActive then return end
    if M.stackCatalog then
        emitStackCatalogPart(M.stackCatalog)
        emitWeightCatalogPart(M.stackCatalog)
        logLine("STACK_CATALOG_INCOMPLETE checked=" .. tostring(M.stackCatalog.checked)
            .. " total=" .. tostring(M.stackCatalog.total)
            .. " reason=game_session_ended_before_audit_finished")
        M.stackCatalog = nil
    end
    logLine("SESSION_END reason=main_menu")
    flushLogLines()
    pcall(ChilaWeightLogJ.endGame)
    sessionActive = false
end

Events.OnKeyPressed.Add(onKeyPressed)
if Events.OnTick then Events.OnTick.Add(onTick) end
if Events.OnGameStart then Events.OnGameStart.Add(onGameStart) end
if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(onMainMenuEnter) end
print("[ChilaSeda_WeightMonitor] loaded v1.9.8; weight and stack-limit scans active; Ctrl+Shift+F7 opens the panel")


