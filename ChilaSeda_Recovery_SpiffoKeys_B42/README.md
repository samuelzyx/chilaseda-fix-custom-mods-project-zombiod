# ChilaSeda Recovery - Spiffo Van Keys (B42)

The local patch scans every `Base.VanSpiffo` within 40 tiles and handles each fuelled van the first time it is detected. It requires more than 0.1 fuel units and ensures Jill has five `Base.CarKey` copies with that vehicle's actual key ID. It counts matching keys in her inventory and nested bags, then adds only the number needed. The scan continues during the session, so vans discovered later along the route are handled too. Existing matching keys prevent duplicates.

The patch keeps a small diagnostic log in `Zomboid/Lua/ChilaSeda_SpiffoKeyRecovery.log` and writes
the same entries to `DebugLog.txt`. It records the vehicle ID, key ID, coordinates, matching key
count, fuel amount, and changes in inventory, ignition, or door state. It excludes empty-fuel vans
and does not change vehicle batteries, fuel, locks, or vehicle ownership.

After Jill confirms she has five keys for each nearby van that had fuel, this temporary recovery
patch can be removed from the profile. Keep the log for future diagnosis before removing the patch.
