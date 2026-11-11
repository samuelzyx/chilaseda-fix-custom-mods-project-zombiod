-- Guard non-inventory tooltip objects before Wilderness QoL reads mod data.
local okCore = pcall(require, "WFI/WFI_Core")
if not okCore or type(WFI) ~= "table" then
    print("[ChilaSeda WFI Fix] Wilderness QoL unavailable; identification guard skipped")
    return
end

if not WFI._ChilaSedaIdentificationGuard then
    local originalIsIdentified = WFI.isIdentified
    if type(originalIsIdentified) == "function" then
        WFI.isIdentified = function(item)
            if not item or not instanceof(item, "InventoryItem") then
                return false
            end
            return originalIsIdentified(item)
        end
        WFI._ChilaSedaIdentificationGuard = true
        print("[ChilaSeda WFI Fix] Identification tooltip guard loaded")
    end
end
