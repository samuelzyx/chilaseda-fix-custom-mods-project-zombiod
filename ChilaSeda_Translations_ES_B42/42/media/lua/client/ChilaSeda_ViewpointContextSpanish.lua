local LABELS_ES = {
    ["add fuel"] = "Agregar combustible",
    ["add fuel to bbq"] = "Agregar combustible a la barbacoa",
    ["bbq add fuel"] = "Agregar combustible a la barbacoa",
    ["extinguish"] = "Apagar fuego",
    ["extinguish fire"] = "Apagar fuego",
    ["bbq extinguish"] = "Apagar fuego de la barbacoa",
    ["pick up fish"] = "Recoger pez",
    ["pickup fish"] = "Recoger pez",
    ["attach lure"] = "Colocar carnada en el anzuelo",
    ["enter vehicle"] = "Entrar al vehiculo",
    ["place item"] = "Colocar objeto",
    ["confirm"] = "Confirmar",
    ["rotate"] = "Girar",
    ["cancel"] = "Cancelar",
}

local function normalize(value)
    if type(value) ~= "string" then return nil end
    value = string.gsub(value, "<[bB][rR]%s*/?>", " ")
    value = string.gsub(value, "<[^>]+>", " ")
    value = string.gsub(value, "[%c]+", " ")
    value = string.gsub(value, "[%p]+", " ")
    value = string.gsub(value, "%s+", " ")
    return string.lower(string.gsub(value, "^%s*(.-)%s*$", "%1"))
end

local function translate(value)
    local key = normalize(value)
    if not key then return value end
    return LABELS_ES[key] or value
end

local function translateAction(action)
    if type(action) ~= "table" then return end
    for _, key in ipairs({ "label", "name", "title", "tooltip", "tip", "description" }) do
        if type(action[key]) == "string" then action[key] = translate(action[key]) end
    end
end

local function installViewpointHarvest()
    local interact = ViewpointInteract
    if not interact or interact.chilaSpanishContextInstalled or type(interact.harvest) ~= "function" then return end
    local original = interact.harvest
    interact.harvest = function(...)
        local result = original(...)
        if type(result) == "table" then
            if type(result.title) == "string" then result.title = translate(result.title) end
            if type(result.labels) == "table" then
                for index, label in ipairs(result.labels) do result.labels[index] = translate(label) end
            end
            for _, action in ipairs(interact.actions or {}) do translateAction(action) end
        end
        return result
    end
    interact.chilaSpanishContextInstalled = true
end

local function installViewpointRegistry()
    local registry = ViewpointUI and ViewpointUI.Interaction and ViewpointUI.Interaction.Registry
    if not registry or registry.chilaSpanishContextInstalled or type(registry.resolve) ~= "function" then return end
    local original = registry.resolve
    registry.resolve = function(...)
        local result = original(...)
        if type(result) == "table" then
            for _, action in ipairs(result.actions or {}) do translateAction(action) end
        end
        return result
    end
    registry.chilaSpanishContextInstalled = true
end

local function install()
    installViewpointHarvest()
    installViewpointRegistry()
end

install()
if Events and Events.OnGameBoot and type(Events.OnGameBoot.Add) == "function" then
    Events.OnGameBoot.Add(install)
end
