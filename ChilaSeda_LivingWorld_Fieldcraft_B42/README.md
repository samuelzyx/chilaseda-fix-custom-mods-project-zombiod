# ChilaSeda Living World Fieldcraft (B42) 0.1.0

This local addon explicitly loads Living World's existing `Fishing.lua`, which registers the `fish` work job. Living World remains responsible for finding water, fetching a rod and bait, fishing, and storing catches.

When local Anomalous Storm data enters its warning or red-rain phases, the addon raises Living World's existing shelter action for NPCs who are outside and have no nearby zombie threat. The action still uses Living World's native `Comfort.shelterNear` route and its 20-tile search. For NPCs ordered to stay, it temporarily relaxes only Living World's base leash while that shelter goal is submitted; forbidden zones and route checks remain active. During a warning, NPCs can move toward shelter before the rain begins.

Bounded diagnostics use the `[ChilaSeda_LivingWorldFieldcraft]` tag. They report fishing module availability and catch outcomes, storm phase transitions, and shelter route attempts. The cap is 128 messages for the session plus at most 32 catch results. Set `TRACE_ENABLED` to `false` after Chila validates the behavior; re-enable it if a related failure returns.

Requires Living World 1.8.1+ and the local `ChilaSeda_AnomalousStorm_B42` mod. Intended for Build 42.22. Workshop originals are not modified. Runtime behavior still needs confirmation in Jill.
