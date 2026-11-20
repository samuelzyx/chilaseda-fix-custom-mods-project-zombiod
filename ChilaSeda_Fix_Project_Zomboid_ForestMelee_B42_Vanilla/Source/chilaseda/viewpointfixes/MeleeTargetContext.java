package chilaseda.viewpointfixes;

import java.util.ArrayDeque;
import java.util.Deque;

import zombie.characters.IsoLivingCharacter;
import zombie.characters.IsoPlayer;
import zombie.characters.IsoZombie;
import zombie.inventory.types.HandWeapon;
import zombie.iso.IsoCell;

/**
 * Per-thread context for the active vanilla melee target calculation.
 *
 * <p>ZombieBuddy inlines advice into {@code zombie.CombatManager}, so every
 * member referenced by that inlined advice must be public.</p>
 */
public final class MeleeTargetContext {
    private static final ThreadLocal<Deque<Target>> STACK = new ThreadLocal<Deque<Target>>() {
        @Override
        protected Deque<Target> initialValue() {
            return new ArrayDeque<>();
        }
    };

    private MeleeTargetContext() {
    }

    public static void push(IsoLivingCharacter attacker, HandWeapon weapon, zombie.iso.IsoMovingObject target) {
        IsoPlayer player = attacker instanceof IsoPlayer ? (IsoPlayer) attacker : null;
        IsoZombie zombie = target instanceof IsoZombie ? (IsoZombie) target : null;
        boolean active = player != null
                && player.isLocalPlayer()
                && weapon != null
                && weapon.isMelee()
                && zombie != null
                && !zombie.isDead();
        STACK.get().push(new Target(player, zombie, active));
    }

    public static Target current() {
        Deque<Target> stack = STACK.get();
        return stack.isEmpty() ? null : stack.peek();
    }

    public static void pop() {
        Deque<Target> stack = STACK.get();
        if (!stack.isEmpty()) {
            stack.pop();
        }
        if (stack.isEmpty()) {
            STACK.remove();
        }
    }

    public static boolean matches(Target target, IsoCell cell,
            int x1, int y1, int z1, int x2, int y2, int z2) {
        if (target == null || !target.active || target.owner.getCell() == null
                || target.owner.getCell() != cell) {
            return false;
        }

        if (z1 != z2
                || z1 != (int) Math.floor(target.owner.getZ())
                || z2 != (int) Math.floor(target.zombie.getZ())) {
            return false;
        }

        int ownerX = (int) Math.floor(target.owner.getX());
        int ownerY = (int) Math.floor(target.owner.getY());
        int zombieX = (int) Math.floor(target.zombie.getX());
        int zombieY = (int) Math.floor(target.zombie.getY());

        boolean ownerToZombie = x1 == ownerX && y1 == ownerY
                && x2 == zombieX && y2 == zombieY;
        boolean zombieToOwner = x2 == ownerX && y2 == ownerY
                && x1 == zombieX && y1 == zombieY;
        return ownerToZombie || zombieToOwner;
    }

    public static final class Target {
        public final IsoPlayer owner;
        public final IsoZombie zombie;
        public final boolean active;

        private Target(IsoPlayer owner, IsoZombie zombie, boolean active) {
            this.owner = owner;
            this.zombie = zombie;
            this.active = active;
        }
    }
}
