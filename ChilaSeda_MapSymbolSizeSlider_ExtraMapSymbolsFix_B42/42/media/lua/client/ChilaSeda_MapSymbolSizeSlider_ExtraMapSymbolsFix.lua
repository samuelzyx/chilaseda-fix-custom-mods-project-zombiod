-- Map Symbol Size Slider 2734705913 treats the preserved extra:x_small ID as
-- proof that the legacy ExtraMapSymbols UI patch is installed. In Jill, the
-- local B42 port only registers symbol definitions; it does not replace the
-- map panel's prerender method. Letting the slider run that legacy recovery
-- rewrites its saved prerender pointer to its own wrapper and recurses.
if not ISWorldMapSymbols or not ISWorldMapSymbols.isExtraMapSymbolsInstalled then
    print("[ChilaSeda Map Symbol Size Slider Fix] expected compatibility hook was not found")
    return
end

function ISWorldMapSymbols:isExtraMapSymbolsInstalled()
    -- Disable only the obsolete prerender-recovery branch. Symbol IDs and
    -- rendering remain available through the normal map symbol list.
    return false
end