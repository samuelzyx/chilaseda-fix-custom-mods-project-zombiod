# Check Around Voice Line Lists Fix

Local compatibility fix for Check Around 1.4.0 on Build 42.21.

It checks the two voice-line lists selected by `ISCheckBehindObject` for doors and windows.
If a recognized target has a missing list, it restores the matching list from Check Around and
prints the runtime object class and list shapes to `DebugLog`. If the selected list is still invalid,
it skips only that voice line so the timed action can finish.

This targets the observed `ApplyVoiceline` failure at `CheckAround.lua:86`. Check Around and Doggy's
Library Workshop files remain untouched. The diagnostics remain available to identify the runtime cause.