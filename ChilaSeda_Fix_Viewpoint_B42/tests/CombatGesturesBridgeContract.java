package chilaseda.viewpointhalo;

import zombie.AttackType;
import zombie.inventory.types.WeaponType;
import zombie.util.list.WeightedList;
import java.lang.reflect.Field;
import java.util.List;

public final class CombatGesturesBridgeContract {
    public static void main(String[] args) throws Exception {
        WeaponType weapon = WeaponType.ONE_HANDED;
        WeightedList<AttackType> vanilla = weapon.getPossibleAttack();

        AttackType swing = CombatGesturesBridge.chooseAttack("swing", weapon);
        AttackType overhead = CombatGesturesBridge.chooseAttack("overhead", weapon);
        AttackType backhand = CombatGesturesBridge.chooseAttack("backhand", weapon);
        if (swing != AttackType.MELEE_SWING || overhead != AttackType.OVERHEAD
                || backhand != AttackType.UPPERCUT) {
            throw new AssertionError("gestures must select distinct vanilla attack animations");
        }

        String armed = CombatGesturesBridge.armAttack(weapon, "swing");
        if (!swing.name().equals(armed)) {
            throw new AssertionError("bridge armed a different attack: " + armed);
        }
        Field valuesField = WeightedList.class.getDeclaredField("list");
        valuesField.setAccessible(true);
        @SuppressWarnings("unchecked")
        List<AttackType> replacementValues = (List<AttackType>) valuesField.get(weapon.getPossibleAttack());
        if (weapon.getPossibleAttack() == vanilla || replacementValues.size() != 1
                || replacementValues.get(0) != swing) {
            throw new AssertionError("bridge did not install the selected attack in the vanilla list");
        }
        if (!"restored".equals(CombatGesturesBridge.restoreAttackOverride("contract"))) {
            throw new AssertionError("bridge did not report restoring vanilla choices");
        }
        if (weapon.getPossibleAttack() != vanilla) {
            throw new AssertionError("bridge did not restore the original WeightedList instance");
        }

        int deltaX = CombatGesturesBridge.mouseDeltaX();
        if (deltaX != 0) throw new AssertionError("uncreated mouse must yield zero delta");
        System.out.println("Combat gesture Java bridge contracts passed");
    }
}
