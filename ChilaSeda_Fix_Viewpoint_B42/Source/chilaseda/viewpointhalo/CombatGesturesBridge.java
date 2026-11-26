package chilaseda.viewpointhalo;

import java.lang.reflect.Field;
import java.util.List;

import me.zed_0xff.zombie_buddy.Exposer;
import org.lwjglx.input.Mouse;
import zombie.AttackType;
import zombie.characters.IsoGameCharacter;
import zombie.characters.IsoPlayer;
import zombie.inventory.types.WeaponType;
import zombie.util.list.WeightedList;

/** Exposes Project Zomboid's combat and mouse APIs to the Lua gesture recognizer. */
@Exposer.LuaClass(name = "ChilaSedaViewpointCombatGesturesJ")
public final class CombatGesturesBridge {
    private static volatile Field possibleAttackField;
    private static volatile Field weightedListValuesField;
    private static WeaponType activeWeaponType;
    private static WeightedList<AttackType> originalAttackList;
    private static boolean warnedRestoreFailure;

    private CombatGesturesBridge() {}

    public static boolean available() {
        try {
            return Mouse.isCreated()
                    && AttackType.MELEE_SWING != null
                    && WeaponType.UNARMED != null
                    && new WeightedList<AttackType>() != null;
        } catch (Throwable unavailable) {
            return false;
        }
    }

    public static int mouseDeltaX() {
        try {
            return Mouse.getDX();
        } catch (Throwable unavailable) {
            return 0;
        }
    }

    public static int mouseDeltaY() {
        try {
            return Mouse.getDY();
        } catch (Throwable unavailable) {
            return 0;
        }
    }

    public static boolean leftMouseDown() {
        try {
            return Mouse.isButtonDown(0);
        } catch (Throwable unavailable) {
            return false;
        }
    }

    public static String armAttack(IsoGameCharacter player, String gestureKind) {
        if (player == null) return "! no player";
        try {
            return armAttack(WeaponType.getWeaponType(player), gestureKind);
        } catch (Throwable error) {
            return failure("weapon type lookup failed", error);
        }
    }

    static synchronized String armAttack(WeaponType weaponType, String gestureKind) {
        if (weaponType == null) return "! no melee weapon type";
        if (weaponType.isRanged()) return "! ranged weapon";
        try {
            AttackType attack = chooseAttack(gestureKind, weaponType);
            if (attack == null) return "! no matching vanilla attack for " + weaponType.name();
            if (activeWeaponType != null) restoreAttackOverride("replacing an unfinished click");

            WeightedList<AttackType> replacement = new WeightedList<>();
            replacement.add(attack, 1);
            Field field = possibleAttackField();
            @SuppressWarnings("unchecked")
            WeightedList<AttackType> original = (WeightedList<AttackType>) field.get(weaponType);
            if (original == null) return "! vanilla attack list was null";
            field.set(weaponType, replacement);
            activeWeaponType = weaponType;
            originalAttackList = original;
            System.out.println("[ChilaSeda_ViewpointCombatGestures] armed "
                    + gestureKind + " weapon=" + weaponType.name() + " attack=" + attack.name());
            return attack.name();
        } catch (Throwable error) {
            return failure("could not arm vanilla attack", error);
        }
    }

    static synchronized AttackType chooseAttack(String gestureKind, WeaponType weaponType) throws Exception {
        List<AttackType> available = values(weaponType.getPossibleAttack());
        boolean floorExecution = "execute".equals(gestureKind);
        for (String candidate : candidatesFor(gestureKind, weaponType)) {
            AttackType attack;
            try {
                attack = AttackType.valueOf(candidate);
            } catch (IllegalArgumentException unknown) {
                continue;
            }
            // The vanilla lists often contain only DEFAULT. This bridge replaces
            // that list for one click, so use the requested vanilla animation.
            if (floorExecution || available.contains(attack) || !"execute".equals(gestureKind)) {
                return attack;
            }
        }
        return null;
    }

    private static String[] candidatesFor(String kind, WeaponType weaponType) {
        if ("execute".equals(kind)) {
            if (weaponType == WeaponType.KNIFE) return new String[] { "MELEE_STAB_TO_FLOOR" };
            if (weaponType == WeaponType.UNARMED) return new String[] { "STOMP", "MELEE_TO_FLOOR" };
            return new String[] { "MELEE_TO_FLOOR", "STOMP", "MELEE_STAB_TO_FLOOR" };
        }
        if ("overhead".equals(kind)) return new String[] { "OVERHEAD", "DEFAULT" };
        if ("backhand".equals(kind)) return new String[] { "UPPERCUT", "DEFAULT" };
        return new String[] { "MELEE_SWING" };
    }

    private static List<AttackType> values(WeightedList<AttackType> weightedList) throws Exception {
        Field field = weightedListValuesField;
        if (field == null) {
            field = WeightedList.class.getDeclaredField("list");
            field.setAccessible(true);
            weightedListValuesField = field;
        }
        @SuppressWarnings("unchecked")
        List<AttackType> values = (List<AttackType>) field.get(weightedList);
        return values;
    }

    private static Field possibleAttackField() throws Exception {
        Field field = possibleAttackField;
        if (field == null) {
            field = WeaponType.class.getDeclaredField("possibleAttack");
            field.setAccessible(true);
            possibleAttackField = field;
        }
        return field;
    }

    public static synchronized String restoreAttackOverride(String reason) {
        if (activeWeaponType == null) return "no active override";
        try {
            possibleAttackField().set(activeWeaponType, originalAttackList);
            System.out.println("[ChilaSeda_ViewpointCombatGestures] restored vanilla attack choices reason="
                    + String.valueOf(reason));
            activeWeaponType = null;
            originalAttackList = null;
            return "restored";
        } catch (Throwable error) {
            if (!warnedRestoreFailure) {
                warnedRestoreFailure = true;
                System.out.println("[ChilaSeda_ViewpointCombatGestures] restore failed: "
                        + error.getClass().getName() + ": " + String.valueOf(error.getMessage()));
            }
            activeWeaponType = null;
            originalAttackList = null;
            return "restore failed";
        }
    }

    public static String attackTypeName(IsoPlayer player) {
        if (player == null) return "";
        try {
            AttackType attack = player.getAttackType();
            return attack == null ? "" : attack.name();
        } catch (Throwable unavailable) {
            return "";
        }
    }

    private static String failure(String message, Throwable error) {
        String reason = message + ": " + error.getClass().getName() + ": "
                + String.valueOf(error.getMessage());
        System.out.println("[ChilaSeda_ViewpointCombatGestures] " + reason);
        return "! " + reason;
    }
}
