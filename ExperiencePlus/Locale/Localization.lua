LatencyGuardLocalization = {}
local L = LatencyGuardLocalization

local locale = GetLocale()

-- English (default language)
L["LatencyGuard"] = "LatencyGuard"
L["LatencyGuard Configuration"] = "LatencyGuard Configuration"
L["Customize the behavior of LatencyGuard."] = "Customize the behavior of LatencyGuard"
L["Enable LatencyGuard"] = "Enable LatencyGuard"
L["Enable Feedback Messages"] = "Enable Feedback Messages"
L["Latency Threshold: 10"] = "Latency Threshold: 10"
L["Latency Threshold: "] = "Latency Threshold: "
L["Latency Threshold"] = "Latency Threshold"
L["Adjust this value to set the latency threshold for your addon."] = "Adjust this value to set the latency threshold for your addon"

-- German (deDE)
if locale == "deDE" then
	L["LatencyGuard"] = "LatenzWächter"
	L["LatencyGuard Configuration"] = "Konfiguration des LatenzWächters"
	L["Customize the behavior of LatencyGuard."] = "Passe das Verhalten des LatenzWächters an."
	L["Enable LatencyGuard"] = "LatenzWächter aktivieren"
	L["Enable Feedback Messages"] = "Feedback-Nachrichten aktivieren"
	L["Latency Threshold: 10"] = "Latenzschwelle: 10"
	L["Latency Threshold: "] = "Latenzschwelle: "
	L["Latency Threshold"] = "Latenzschwelle"
	L["Adjust this value to set the latency threshold for your addon."] = "Passe diesen Wert an, um die Latenzschwelle für dein Addon festzulegen."
end

-- French (frFR)
if locale == "frFR" then
	L["LatencyGuard"] = "Garde de latence"
	L["LatencyGuard Configuration"] = "Configuration de la Garde de latence"
	L["Customize the behavior of LatencyGuard."] = "Personnalisez le comportement de la Garde de latence."
	L["Enable LatencyGuard"] = "Activer la Garde de latence"
	L["Enable Feedback Messages"] = "Activer les messages de retour"
	L["Latency Threshold: 10"] = "Seuil de latence : 10"
	L["Latency Threshold: "] = "Seuil de latence : "
	L["Latency Threshold"] = "Seuil de latence"
	L["Adjust this value to set the latency threshold for your addon."] = "Ajustez cette valeur pour définir le seuil de latence de votre addon."
end

-- Add additional languages following the same pattern

-- Function to handle localization
function GetLocalization(string)
	return L[string] or string
end

-- Usage
-- local text = GetLocalization("LatencyGuard Configuration")
