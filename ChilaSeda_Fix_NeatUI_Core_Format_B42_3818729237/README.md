# ChilaSeda - NeatUI Core Format Fix

Fixes the NeatUI Core options-menu crash caused by raw percent signs in the `ICON_SCALE` and `OPACITY` slider labels. The patch escapes the percent signs immediately before Project Zomboid builds the mod-options panel; the displayed labels remain unchanged.

Requires NeatUI Core and loads after its options page and the Viewpoint options hooks. It does not edit the Workshop mod or touch world data.
