local _, latencyGuard = ...

latencyGuard.ScreenWidth = GetPhysicalScreenSize()

latencyGuard:RegisterSettings("ExperiencePlusDB", {
	{
		key = "enableExp",
		type = "toggle",
		title = "Enable",
		tooltip = "Toggle the display of NexEnhances experience bar.",
		default = true,
	},
	{
		key = "showBubbles",
		type = "toggle",
		title = "Show Bubbles",
		tooltip = "Show bubbles on experience / rep bars.",
		default = true,
	},
	{
		key = "barWidth",
		type = "slider",
		title = "Bar Width",
		tooltip = "Adjust the width of the bar. Default is 500. Minimum is 200. Maximum is the screen width.",
		default = 570,
		minValue = 200,
		maxValue = latencyGuard.ScreenWidth,
		valueStep = 1,
	},
	{
		key = "barHeight",
		type = "slider",
		title = "Bar Height",
		tooltip = "Adjust the height of the bar. Default is 12. Minimum is 10. Maximum is 40.",
		default = 12,
		minValue = 10,
		maxValue = 40,
		valueStep = 1,
	},
	{
		key = "numberFormat",
		type = "menu",
		title = "Number Format",
		tooltip = "Choose the format for numbers.",
		default = 1,
		options = {
			[1] = "Standard: b/m/k",
			[2] = "Asian: y/w",
			[3] = "Full digitals",
		},
	},
	{
		key = "barTextFormat",
		type = "menu",
		title = "Bar Text Format",
		tooltip = "Choose the format for the text on the bar",
		default = "CURPERC",
		options = {
			["PERCENT"] = "Percent",
			["CURMAX"] = "Current - Max",
			["CURPERC"] = "Current - Percent",
			["CUR"] = "Current",
			["REM"] = "Remaining",
			["CURREM"] = "Current - Remaining",
			["CURPERCREM"] = "Current - Percent (Remaining)",
		},
	},
	{
		key = "tempAnchor",
		default = { "TOP", "UIParent", "TOP", 0, -6 },
	},
})

latencyGuard:RegisterSettingsSlash("/lg")
