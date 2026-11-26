# ChilaSeda Fix - Project Zomboid Forward Direction (B42, Vanilla) 1.0.0

Guards the `IsoGameCharacter.setForwardDirection(Vector2)` vanilla method against an exactly zero-length vector. It skips only that invalid update, preserving the actor's previously stored facing. Nonzero vectors continue through the original method unchanged.

Build 42.22.2 vanilla `LungeState.execute` copies `IsoZombie.vectorToTarget`, normalizes it and passes it to `setForwardDirection` without checking for zero length. Jill's `2026-11-24_18-27_DebugLog.txt` recorded 16 `LungeState` exceptions from that call. The local guard writes at most 32 `[ChilaSeda_ForwardDirectionFix]` lines, including the prior facing and fallback. `shouldSkip` must remain public because ZombieBuddy injects the check into `zombie.characters.IsoGameCharacter`; the Nov 25 console confirmed package-private access crashes with `IllegalAccessError`. `TRACE_ENABLED` and `setTraceEnabled` allow diagnostics to be disabled after validation and re-enabled if the error returns.

Requires ZombieBuddy 2.3.4+. The Workshop game files remain unchanged. Runtime validation is pending.
