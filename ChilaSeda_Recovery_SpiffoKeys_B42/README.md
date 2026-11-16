# ChilaSeda Recovery - Spiffo Van Keys (B42)

On Jill's next load, this local patch finds the two nearest `Base.VanSpiffo` vehicles within
40 tiles. It ensures Jill has five `Base.CarKey` copies per vehicle, each with that vehicle's
actual key ID. It counts matching keys in her inventory and nested bags, then adds only the number
needed to reach five. A player mod-data flag prevents the recovery from running again on later loads.

The patch keeps a small diagnostic log in `Zomboid/Lua/ChilaSeda_SpiffoKeyRecovery.log` and writes
the same entries to `DebugLog.txt`. It records the vehicle ID, key ID, coordinates, matching key
count, and changes in inventory, ignition, or door state. It does not change vehicle batteries,
fuel, locks, or vehicle ownership.

After Jill confirms both keys are back, this temporary recovery patch can be removed from the
profile. Keep the log for future diagnosis before removing the patch.
