# ChilaSeda - Moats Fill Level (B42) 0.1.1

Adds a read-only water status entry to Viewpoint's world interaction list when the selected square contains an unfinished Moats tile. The entry shows the synchronized fluid amount, capacity, percentage, and the amount still needed for the tile to become normal water. Hovering the entry explains the conversion and repeats the measured values.

The displayed amount comes from the tile's fluid container (with Moats mod data as a fallback); capacity comes from the tile's saved `waterMax`, then the vanilla large rain-collector capacity used by Moats when the tile is created. It does not estimate progress from elapsed time. Once Moats converts the filled tile into vanilla water, the Moats sprite is gone and this status entry stops appearing.

The patch loads after `MoatsB42`, `Viewpoint`, and `ChilaSeda_Fix_Viewpoint_B42`. It leaves Workshop files untouched. A bounded `[ChilaSeda_MoatsFillLevel]` trace records hook installation, status display, and data/API fallbacks during Jill validation.
