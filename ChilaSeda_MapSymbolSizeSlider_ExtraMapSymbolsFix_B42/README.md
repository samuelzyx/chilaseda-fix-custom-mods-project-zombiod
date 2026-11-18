# ChilaSeda Map Symbol Size Slider - Extra Map Symbols Fix (B42)

This local patch prevents a stack overflow in Workshop Map Symbol Size Slider (2734705913) when Jill uses the local B42 Extra Map Symbols definitions.

The slider detects the preserved `extra:x_small` ID and assumes the legacy ExtraMapSymbols UI is replacing `ISWorldMapSymbols.prerender`. In this setup, the local port only registers symbol definitions. The slider's compatibility recovery therefore captures its own prerender wrapper as the original and recurses. The patch disables only that obsolete detection hook; symbol definitions, the size slider, and the map's normal tabs remain enabled.

Load after `MapSymbolSizeSlider` and `ChilaSeda_RecentMapSymbols_ExtraMapSymbols_B42`.