-- Global variables
local _, ExperiencePlus = ...

-- Caching global functions and variables
local math_min, math_floor = math.min, math.floor
local string_format = string.format
local select, pairs = select, pairs

-- Caching frequently used functions and variables
local GetXPExhaustion = GetXPExhaustion
local IsWatchingHonorAsXP = IsWatchingHonorAsXP
local UnitHonor, UnitHonorLevel, UnitHonorMax = UnitHonor, UnitHonorLevel, UnitHonorMax
local UnitXP, UnitXPMax = UnitXP, UnitXPMax
local C_AzeriteItem_FindActiveAzeriteItem = C_AzeriteItem.FindActiveAzeriteItem
local C_AzeriteItem_GetAzeriteItemXPInfo = C_AzeriteItem.GetAzeriteItemXPInfo
local C_AzeriteItem_GetPowerLevel = C_AzeriteItem.GetPowerLevel
local C_GossipInfo_GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation
local C_MajorFactions_GetMajorFactionData = C_MajorFactions.GetMajorFactionData
local C_MajorFactions_HasMaximumRenown = C_MajorFactions.HasMaximumRenown
local C_Reputation_GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo
local C_Reputation_IsFactionParagon, C_Reputation_IsMajorFaction = C_Reputation.IsFactionParagon, C_Reputation.IsMajorFaction
local GameTooltip, GetWatchedFactionInfo = GameTooltip, GetWatchedFactionInfo

local barWidth, barHeight, barTextFormat, enableExp, showBubbles

ExperiencePlus:RegisterOptionCallback("enableExp", function(value)
	enableExp = value
end)

ExperiencePlus:RegisterOptionCallback("showBubbles", function(value)
	showBubbles = value
	if ExperiencePlus.bar then
		ExperiencePlus:ManageBarBubbles(ExperiencePlus.bar)
	end
end)

ExperiencePlus:RegisterOptionCallback("barWidth", function(value)
	barWidth = value
	if ExperiencePlus.bar then
		ExperiencePlus.bar:SetWidth(barWidth)
		ExperiencePlus:ManageBarBubbles(ExperiencePlus.bar)
	end
end)

ExperiencePlus:RegisterOptionCallback("barHeight", function(value)
	barHeight = value
	if ExperiencePlus.bar then
		ExperiencePlus.bar:SetHeight(barHeight)
		ExperiencePlus:ManageBarBubbles(ExperiencePlus.bar)
		ExperiencePlus:ForceTextScaling(ExperiencePlus.bar)
	end
end)

ExperiencePlus:RegisterOptionCallback("barTextFormat", function(value)
	barTextFormat = value
	if ExperiencePlus.bar then
		ExperiencePlus.OnExpBarEvent(ExperiencePlus.bar)
	end
end)

-- Experience
local CurrentXP, XPToLevel, PercentRested, PercentXP, RemainXP, RemainTotal, RemainBars
local RestedXP = 0

local function XPIsUserDisabled()
	return IsXPUserDisabled()
end

local function XPIsTrialMax()
	return (IsRestrictedAccount() or IsTrialAccount() or IsVeteranTrialAccount()) and (ExperiencePlus.MyLevel == 20)
end

local function XPIsLevelMax()
	return IsLevelAtEffectiveMaxLevel(ExperiencePlus.MyLevel) or XPIsUserDisabled() or XPIsTrialMax()
end

-- Reputation
local function RepGetValues(curValue, minValue, maxValue)
	local maximum = maxValue - minValue
	local current, diff = curValue - minValue, maximum

	if diff == 0 then
		diff = 1
	end -- prevent a division by zero

	if current == maximum then
		return 1, 1, 100, true
	else
		return current, maximum, current / diff * 100
	end
end
-- Honor
local CurrentHonor, MaxHonor, CurrentLevel, PercentHonor, RemainingHonor

-- Azerite
local azeriteItem, currentLevel, curXP, maxXP

local function IsAzeriteAvailable()
	local itemLocation = C_AzeriteItem_FindActiveAzeriteItem()
	return itemLocation and itemLocation:IsEquipmentSlot() and not C_AzeriteItem.IsAzeriteItemAtMaxLevel()
end

-- Bar string
local barDisplayString = ""

function ExperiencePlus:OnExpBarEvent(event, unit)
	if not XPIsLevelMax() then
		CurrentXP, XPToLevel, RestedXP = UnitXP("player"), UnitXPMax("player"), (GetXPExhaustion() or 0)

		-- Ensure XPToLevel is not 0 to avoid division by zero
		if XPToLevel <= 0 then
			XPToLevel = 1
		end

		-- Calculate remaining XP and percentage
		local remainXP = XPToLevel - CurrentXP
		local remainPercent = remainXP / XPToLevel
		RemainTotal, RemainBars = remainPercent * 100, remainPercent * 20
		PercentXP, RemainXP = (CurrentXP / XPToLevel) * 100, ExperiencePlus.ShortValue(remainXP)

		-- Set status bar colors
		self:SetStatusBarColor(0, 0.4, 1, 0.8)
		self.restBar:SetStatusBarColor(1, 0, 1, 0.4)

		-- Set up main XP bar
		self:SetMinMaxValues(0, XPToLevel)
		self:SetValue(CurrentXP)

		if barTextFormat == "PERCENT" then
			barDisplayString = format(XP .. ": %.2f%%", PercentXP)
		elseif barTextFormat == "CURMAX" then
			barDisplayString = format(XP .. ": %s - %s", ExperiencePlus.ShortValue(CurrentXP), ExperiencePlus.ShortValue(XPToLevel))
		elseif barTextFormat == "CURPERC" then
			barDisplayString = format(XP .. ": %s - %.2f%%", ExperiencePlus.ShortValue(CurrentXP), PercentXP)
		elseif barTextFormat == "CUR" then
			barDisplayString = format(XP .. ": %s", ExperiencePlus.ShortValue(CurrentXP))
		elseif barTextFormat == "REM" then
			barDisplayString = format(XP .. ": %s", RemainXP)
		elseif barTextFormat == "CURREM" then
			barDisplayString = format(XP .. ": %s - %s", ExperiencePlus.ShortValue(CurrentXP), RemainXP)
		elseif barTextFormat == "CURPERCREM" then
			barDisplayString = format(XP .. ": %s - %.2f%% (%s)", ExperiencePlus.ShortValue(CurrentXP), PercentXP, RemainXP)
		end

		-- Check if rested XP exists
		local isRested = RestedXP > 0
		if isRested then
			-- Set up rested XP bar
			self.restBar:SetMinMaxValues(0, XPToLevel)
			self.restBar:SetValue(math_min(CurrentXP + RestedXP, XPToLevel))

			-- Calculate percentage of rested XP
			PercentRested = (RestedXP / XPToLevel) * 100

			if barTextFormat == "PERCENT" then
				barDisplayString = format("%s R:%.2f%%", barDisplayString, PercentRested)
			elseif barTextFormat == "CURPERC" then
				barDisplayString = format("%s R:%s [%.2f%%]", barDisplayString, ExperiencePlus.ShortValue(RestedXP), PercentRested)
			elseif barTextFormat ~= "NONE" then
				barDisplayString = format("%s R:%s", barDisplayString, ExperiencePlus.ShortValue(RestedXP))
			end
		end

		-- Show experience
		self:Show()

		-- Show or hide rested XP bar based on rested state
		self.restBar:SetShown(isRested)

		-- Update text display with XP information
		self.text:SetText(barDisplayString)
	elseif GetWatchedFactionInfo() then
		local standing, rewardPending, _
		local name, reaction, minValue, maxValue, curValue, factionID = GetWatchedFactionInfo()

		local info = factionID and C_GossipInfo_GetFriendshipReputation(factionID)
		if info and info.friendshipFactionID and info.friendshipFactionID > 0 then
			standing, minValue, maxValue, curValue = info.reaction, info.reactionThreshold or 0, info.nextThreshold or math.huge, info.standing or 1
		end

		if not standing and factionID and C_Reputation_IsFactionParagon(factionID) then
			local current, threshold
			current, threshold, _, rewardPending = C_Reputation_GetFactionParagonInfo(factionID)

			if current and threshold then
				standing, minValue, maxValue, curValue, reaction = ExperiencePlus.L["Paragon"], 0, threshold, current % threshold, 9
			end
		end

		if not standing and factionID and C_Reputation_IsMajorFaction(factionID) then
			local majorFactionData = C_MajorFactions_GetMajorFactionData(factionID)
			local renownColor = { r = 0, g = 0.74, b = 0.95 }
			local renownHex = ExperiencePlus.RGBToHex(renownColor.r, renownColor.g, renownColor.b)

			reaction, minValue, maxValue = 10, 0, majorFactionData.renownLevelThreshold
			curValue = C_MajorFactions_HasMaximumRenown(factionID) and majorFactionData.renownLevelThreshold or majorFactionData.renownReputationEarned or 0
			standing = string_format("%s%s %s|r", renownHex, RENOWN_LEVEL_LABEL, majorFactionData.renownLevel)
		end

		if not standing then
			standing = _G["FACTION_STANDING_LABEL" .. reaction] or UNKNOWN
		end

		local color = FACTION_BAR_COLORS[reaction] or { r = 0, g = 0.74, b = 0.95 }
		local total = maxValue == math.huge and 1 or maxValue -- we need to correct the min/max of friendship factions to display the bar at 100%

		self:SetStatusBarColor(color.r or 1, color.g or 1, color.b or 1, 1)
		self:SetMinMaxValues((maxValue == math.huge or minValue == maxValue) and 0 or minValue, total) -- we force min to 0 because the min will match max when a rep is maxed and cause the bar to be 0%
		self:SetValue(curValue)

		self.reward:ClearAllPoints()
		self.reward:SetPoint("CENTER", self, "LEFT")
		self.reward:SetShown(rewardPending)

		local current, maximum, percent, capped = RepGetValues(curValue, minValue, total)
		if capped and barTextFormat ~= "NONE" then -- show only name and standing on exalted
			barDisplayString = format("%s: [%s]", name, standing)
		elseif barTextFormat == "PERCENT" then
			barDisplayString = format("%s: %d%% [%s]", name, percent, standing)
		elseif barTextFormat == "CURMAX" then
			barDisplayString = format("%s: %s - %s [%s]", name, ExperiencePlus.ShortValue(current), ExperiencePlus.ShortValue(maximum), standing)
		elseif barTextFormat == "CURPERC" then
			barDisplayString = format("%s: %s - %d%% [%s]", name, ExperiencePlus.ShortValue(current), percent, standing)
		elseif barTextFormat == "CUR" then
			barDisplayString = format("%s: %s [%s]", name, ExperiencePlus.ShortValue(current), standing)
		elseif barTextFormat == "REM" then
			barDisplayString = format("%s: %s [%s]", name, ExperiencePlus.ShortValue(maximum - current), standing)
		elseif barTextFormat == "CURREM" then
			barDisplayString = format("%s: %s - %s [%s]", name, ExperiencePlus.ShortValue(current), ExperiencePlus.ShortValue(maximum - current), standing)
		elseif barTextFormat == "CURPERCREM" then
			barDisplayString = format("%s: %s - %d%% (%s) [%s]", name, ExperiencePlus.ShortValue(current), percent, ExperiencePlus.ShortValue(maximum - current), standing)
		end

		self:Show()
		self.text:SetText(barDisplayString)
	elseif IsWatchingHonorAsXP() then
		if event == "PLAYER_FLAGS_CHANGED" and unit ~= "player" then
			return
		end

		CurrentHonor, MaxHonor, CurrentLevel = UnitHonor("player"), UnitHonorMax("player"), UnitHonorLevel("player")

		-- Guard against division by zero, which appears to be an issue when zoning in/out of dungeons
		if MaxHonor == 0 then
			MaxHonor = 1
		end

		PercentHonor, RemainingHonor = (CurrentHonor / MaxHonor) * 100, MaxHonor - CurrentHonor
		if RemainingHonor == 0 then
			RemainingHonor = 1
		end

		local colorHonor = { r = 0.94, g = 0.45, b = 0.25 }

		self:SetMinMaxValues(0, MaxHonor)
		self:SetValue(CurrentHonor)
		self:SetStatusBarColor(colorHonor.r, colorHonor.g, colorHonor.b)

		if barTextFormat == "PERCENT" then
			barDisplayString = format(HONOR .. ": %d%% - [%s]", PercentHonor, CurrentLevel)
		elseif barTextFormat == "CURMAX" then
			barDisplayString = format(HONOR .. ": %s - %s - [%s]", ExperiencePlus.ShortValue(CurrentHonor), ExperiencePlus.ShortValue(MaxHonor), CurrentLevel)
		elseif barTextFormat == "CURPERC" then
			barDisplayString = format(HONOR .. ": %s - %d%% - [%s]", ExperiencePlus.ShortValue(CurrentHonor), PercentHonor, CurrentLevel)
		elseif barTextFormat == "CUR" then
			barDisplayString = format(HONOR .. ": %s - [%s]", ExperiencePlus.ShortValue(CurrentHonor), CurrentLevel)
		elseif barTextFormat == "REM" then
			barDisplayString = format(HONOR .. ": %s - [%s]", ExperiencePlus.ShortValue(RemainingHonor), CurrentLevel)
		elseif barTextFormat == "CURREM" then
			barDisplayString = format(HONOR .. ": %s - %s - [%s]", ExperiencePlus.ShortValue(CurrentHonor), ExperiencePlus.ShortValue(RemainingHonor), CurrentLevel)
		elseif barTextFormat == "CURPERCREM" then
			barDisplayString = format(HONOR .. ": %s - %d%% (%s) - [%s]", ExperiencePlus.ShortValue(CurrentHonor), CurrentHonor, ExperiencePlus.ShortValue(RemainingHonor), CurrentLevel)
		end

		self:Show()
		self.text:SetText(barDisplayString)
	elseif IsAzeriteAvailable() then
		if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then
			return
		end

		local item = C_AzeriteItem_FindActiveAzeriteItem()
		local cur, max = C_AzeriteItem_GetAzeriteItemXPInfo(item)
		local currentLevel = C_AzeriteItem_GetPowerLevel(item)
		local color = { 0.901, 0.8, 0.601, 1 }

		self:SetStatusBarColor(color.r, color.g, color.b, color.a)
		self:SetMinMaxValues(0, max)
		self:SetValue(cur)

		if barTextFormat == "NONE" then
			barDisplayString = format("")
		elseif barTextFormat == "PERCENT" then
			barDisplayString = format("%s%% [%s]", floor(cur / max * 100), currentLevel)
		elseif barTextFormat == "CURMAX" then
			barDisplayString = format("%s - %s [%s]", ExperiencePlus.ShortValue(cur), ExperiencePlus.ShortValue(max), currentLevel)
		elseif barTextFormat == "CURPERC" then
			barDisplayString = format("%s - %s%% [%s]", ExperiencePlus.ShortValue(cur), floor(cur / max * 100), currentLevel)
		elseif barTextFormat == "CUR" then
			barDisplayString = format("%s [%s]", ExperiencePlus.ShortValue(cur), currentLevel)
		elseif barTextFormat == "REM" then
			barDisplayString = format("%s [%s]", ExperiencePlus.ShortValue(max - cur), currentLevel)
		elseif barTextFormat == "CURREM" then
			barDisplayString = format("%s - %s [%s]", ExperiencePlus.ShortValue(cur), ExperiencePlus.ShortValue(max - cur), currentLevel)
		elseif barTextFormat == "CURPERCREM" then
			barDisplayString = format("%s - %s%% (%s) [%s]", ExperiencePlus.ShortValue(cur), floor(cur / max * 100), ExperiencePlus.ShortValue(max - cur), currentLevel)
		else
			barDisplayString = format("[%s]", currentLevel)
		end

		self:Show()
		self.text:SetText(barDisplayString)
	elseif HasArtifactEquipped() then
		if C_ArtifactUI.IsEquippedArtifactDisabled() then
			self:SetStatusBarColor(0.6, 0.6, 0.6)
			self:SetMinMaxValues(0, 1)
			self:SetValue(1)
		else
			local _, _, _, _, totalXP, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
			local _, xp, xpForNextPoint = ArtifactBarGetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP, artifactTier)
			xp = xpForNextPoint == 0 and 0 or xp
			self:SetStatusBarColor(0.9, 0.8, 0.6)
			self:SetMinMaxValues(0, xpForNextPoint)
			self:SetValue(xp)
		end
		self:Show()
	else
		self:Hide()
		self.text:SetText("")
	end
end

function ExperiencePlus:OnExpBarEnter()
	if GameTooltip:IsForbidden() then
		return
	end

	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")

	-- Experience Tooltip
	if not XPIsLevelMax() then
		GameTooltip:AddDoubleLine("|cff0070ff" .. COMBAT_XP_GAIN .. "|r", format("%s %d", LEVEL, ExperiencePlus.MyLevel))

		if CurrentXP then
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(ExperiencePlus.L["XP:"], string_format(" %s / %s (%.2f%%)", ExperiencePlus.ShortValue(CurrentXP), ExperiencePlus.ShortValue(XPToLevel), PercentXP), 1, 1, 1)
		end

		if RemainXP then
			GameTooltip:AddDoubleLine(ExperiencePlus.L["Remaining:"], string_format(" %s (%.2f%% - %.2f " .. ExperiencePlus.L["Bars"] .. ")", RemainXP, RemainTotal, RemainBars), 1, 1, 1)
		end

		if RestedXP > 0 then
			GameTooltip:AddDoubleLine(ExperiencePlus.L["Rested:"], string_format("+%s (%.2f%%)", ExperiencePlus.ShortValue(RestedXP), PercentRested), 1, 1, 1)
		end

		if IsXPUserDisabled() then
			GameTooltip:AddLine("|cffff0000" .. XP .. LOCKED)
		end
	end

	if GetWatchedFactionInfo() then
		if not XPIsLevelMax() then
			GameTooltip:AddLine("|cff7b8489" .. "---------------")
		end

		local name, reaction, minValue, maxValue, curValue, factionID = GetWatchedFactionInfo()
		local isParagon = factionID and C_Reputation_IsFactionParagon(factionID)
		local standing

		if isParagon then
			local current, threshold = C_Reputation_GetFactionParagonInfo(factionID)
			if current and threshold then
				standing, minValue, maxValue, curValue = ExperiencePlus.L["Paragon"], 0, threshold, current % threshold
			end
		end

		if name then
			local repNameColor = FACTION_BAR_COLORS[reaction] or { r = 0, g = 0.74, b = 0.95 }
			GameTooltip:AddDoubleLine(REPUTATION, name, 0, 0.74, 0.95, repNameColor.r, repNameColor.g, repNameColor.b)
			GameTooltip:AddLine(" ")

			local info = factionID and C_GossipInfo.GetFriendshipReputation(factionID)
			if info and info.friendshipFactionID and info.friendshipFactionID > 0 then
				standing, minValue, maxValue, curValue = info.reaction, info.reactionThreshold or 0, info.nextThreshold or math.huge, info.standing or 1
			end

			if not standing then
				standing = _G["FACTION_STANDING_LABEL" .. reaction] or UNKNOWN
			end

			local isMajorFaction = factionID and C_Reputation_IsMajorFaction(factionID)
			if not isMajorFaction then
				GameTooltip:AddDoubleLine(STANDING .. ":", standing, 1, 1, 1)
			end

			if not isParagon and isMajorFaction then
				local majorFactionData = C_MajorFactions_GetMajorFactionData(factionID)
				curValue = (C_MajorFactions_HasMaximumRenown(factionID) and majorFactionData.renownLevelThreshold) or majorFactionData.renownReputationEarned or 0
				maxValue = majorFactionData.renownLevelThreshold
				GameTooltip:AddDoubleLine(RENOWN_LEVEL_LABEL .. majorFactionData.renownLevel, string_format("%d / %d (%d%%)", RepGetValues(curValue, 0, maxValue)), BLUE_FONT_COLOR.r, BLUE_FONT_COLOR.g, BLUE_FONT_COLOR.b, 1, 1, 1)
			elseif (isParagon or (reaction ~= _G.MAX_REPUTATION_REACTION)) and maxValue ~= math.huge then
				GameTooltip:AddDoubleLine(REPUTATION .. ":", string_format("%d / %d (%d%%)", RepGetValues(curValue, minValue, maxValue)), 1, 1, 1)
			end

			-- Check for specific faction
			if factionID == 2465 then -- Translate "荒猎团" if necessary
				local repInfo = C_GossipInfo_GetFriendshipReputation(2463) -- Translate "玛拉斯缪斯" if necessary
				local rep, name, reaction, threshold, nextThreshold = repInfo.standing, repInfo.name, repInfo.reaction, repInfo.reactionThreshold, repInfo.nextThreshold
				if nextThreshold and rep > 0 then
					local current = rep - threshold
					local currentMax = nextThreshold - threshold
					GameTooltip:AddLine(" ") -- Translate if necessary
					GameTooltip:AddLine(name, 0, 0.6, 1) -- Translate "name" if necessary
					GameTooltip:AddDoubleLine(reaction, current .. " / " .. currentMax .. " (" .. floor(current / currentMax * 100) .. "%)", 0.6, 0.8, 1, 1, 1, 1) -- Translate "reaction" if necessary
				end
			end
		end
	end

	if IsWatchingHonorAsXP() then
		GameTooltip:AddLine(HONOR)

		GameTooltip:AddDoubleLine("Current Level:", CurrentLevel, 1, 1, 1)
		GameTooltip:AddLine(" ")

		GameTooltip:AddDoubleLine(ExperiencePlus.L["Honor XP"], string_format(" %d / %d (%d%%)", CurrentHonor, MaxHonor, PercentHonor), 1, 1, 1)
		if RemainingHonor then
			GameTooltip:AddDoubleLine(ExperiencePlus.L["Honor Remaining:"], format(" %d (%d%% - %d " .. ExperiencePlus.L["Bars"] .. ")", RemainingHonor, RemainingHonor / MaxHonor * 100, 20 * RemainingHonor / MaxHonor), 1, 1, 1)
		end
	end

	if IsAzeriteAvailable() then
		local item = C_AzeriteItem_FindActiveAzeriteItem()
		if item then
			curXP, maxXP = C_AzeriteItem_GetAzeriteItemXPInfo(item)
			currentLevel = C_AzeriteItem_GetPowerLevel(item)
			azeriteItem = Item:CreateFromItemLocation(item)
			azeriteItem:ContinueWithCancelOnItemLoad(function()
				GameTooltip:AddDoubleLine(ARTIFACT_POWER, azeriteItem:GetItemName() .. " (" .. currentLevel .. ")", nil, nil, nil, 0.90, 0.80, 0.50) -- Temp Locale
				GameTooltip:AddLine(" ")

				GameTooltip:AddDoubleLine("AP:", string_format(" %d / %d (%d%%)", curXP, maxXP, curXP / maxXP * 100), 1, 1, 1)
				GameTooltip:AddDoubleLine(ExperiencePlus.L["Remaining"], string_format(" %d (%d%% - %d " .. ExperiencePlus.L["Bars"] .. ")", maxXP - curXP, (maxXP - curXP) / maxXP * 100, 10 * (maxXP - curXP) / maxXP), 1, 1, 1)
			end)
		end
	end

	if HasArtifactEquipped() then
		local _, _, name, _, totalXP, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
		local num, xp, xpForNextPoint = ArtifactBarGetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP, artifactTier)
		GameTooltip:AddLine(" ")
		if C_ArtifactUI.IsEquippedArtifactDisabled() then
			GameTooltip:AddLine(name, ExperiencePlus.RGBToHex(0, 0.74, 0.95))
			GameTooltip:AddLine(ARTIFACT_RETIRED, 0.6, 0.8, 1, 1)
		else
			GameTooltip:AddLine(name .. " (" .. format(SPELLBOOK_AVAILABLE_AT, pointsSpent) .. ")", 0, 0.6, 1)
			local numText = num > 0 and " (" .. num .. ")" or ""
			GameTooltip:AddDoubleLine(ARTIFACT_POWER, ExperiencePlus.ShortValue(totalXP) .. numText, 0.6, 0.8, 1, 1, 1, 1)
			if xpForNextPoint ~= 0 then
				local perc = " (" .. floor(xp / xpForNextPoint * 100) .. "%)"
				GameTooltip:AddDoubleLine(ExperiencePlus.L["Next Trait"], ExperiencePlus.ShortValue(xp) .. " / " .. ExperiencePlus.ShortValue(xpForNextPoint) .. perc, 0.6, 0.8, 1, 1, 1, 1)
			end
		end
	end

	GameTooltip:Show()
end

function ExperiencePlus:OnExpBarLeave()
	GameTooltip:Hide()
end

function ExperiencePlus:SetupExpRepScript(bar)
	-- List of events to register
	bar.eventList = {
		"PLAYER_LEVEL_UP",
		"UPDATE_EXHAUSTION",
		"PLAYER_ENTERING_WORLD",
		"UPDATE_FACTION",
		"ARTIFACT_XP_UPDATE",
		"PLAYER_EQUIPMENT_CHANGED",
		"ENABLE_XP_GAIN",
		"DISABLE_XP_GAIN",
		"AZERITE_ITEM_EXPERIENCE_CHANGED",
		"PLAYER_UPDATE_RESTING",
		"HONOR_LEVEL_UPDATE",
		"MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
		"MAJOR_FACTION_UNLOCKED",
	}

	-- List of unit events to register
	bar.unitEventList = {
		"UNIT_INVENTORY_CHANGED",
		"PLAYER_XP_UPDATE",
		"HONOR_XP_UPDATE",
	}

	-- Register events
	for _, event in ipairs(bar.eventList) do
		bar:RegisterEvent(event)
	end

	-- Register unit events for player
	for _, unitEvent in ipairs(bar.unitEventList) do
		bar:RegisterUnitEvent(unitEvent, "player")
	end

	-- Set script handlers
	bar:SetScript("OnEvent", ExperiencePlus.OnExpBarEvent)
	bar:SetScript("OnEnter", ExperiencePlus.OnExpBarEnter)
	bar:SetScript("OnLeave", ExperiencePlus.OnExpBarLeave)

	-- Hook to update bars shown
	hooksecurefunc(StatusTrackingBarManager, "UpdateBarsShown", function()
		ExperiencePlus.OnExpBarEvent(bar)
	end)
end

function ExperiencePlus:ManageBarBubbles(bar)
	if not bar.bubbles then
		bar.bubbles = {}

		for i = 1, 9 do
			bar.bubbles[i] = bar:CreateTexture(nil, "OVERLAY", nil, 0)
			bar.bubbles[i]:SetColorTexture(0.6, 0.6, 0.6, 0.7)
		end
	end

	local width, height = barWidth, barHeight
	local bubbleWidth, bubbleHeight = 1, height - 0
	local offset = width * 0.1

	for i, bubble in ipairs(bar.bubbles) do
		bubble:ClearAllPoints()
		bubble:SetShown(showBubbles)
		bubble:SetSize(bubbleWidth, bubbleHeight)
		bubble:SetPoint("RIGHT", bar, "LEFT", offset * i, 0)
	end
end

function ExperiencePlus:ForceTextScaling(bar)
	local minHeightForScaling = 15
	local defaultFontSize = 11

	if barHeight <= minHeightForScaling then
		bar.text:SetFont(select(1, bar.text:GetFont()), defaultFontSize, select(3, bar.text:GetFont()))
	else
		local fontSize = math.max(defaultFontSize, barHeight * 0.5)
		bar.text:SetFont(select(1, bar.text:GetFont()), fontSize, select(3, bar.text:GetFont()))
	end
end

function ExperiencePlus:PLAYER_LOGIN()
	if not enableExp then
		return
	end

	-- Hide blizzard expbar
	if StatusTrackingBarManager then
		StatusTrackingBarManager:UnregisterAllEvents()
		StatusTrackingBarManager:Hide()
	end

	local bar = CreateFrame("StatusBar", "EP_ExpRepBar", UIParent)
	bar:ClearAllPoints()
	bar:SetPoint("TOP", UIParent, "TOP", 0, -6)
	bar:SetSize(barWidth, barHeight)
	bar:SetHitRectInsets(0, 0, 0, -10)
	bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

	local border = CreateFrame("Frame", nil, bar, "TooltipBackdropTemplate")
	border:SetPoint("TOPLEFT", bar, "TOPLEFT", -4, 4)
	border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 4, -4)
	border:SetFrameLevel(bar:GetFrameLevel() + 0)

	local spark = bar:CreateTexture(nil, "OVERLAY")
	spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	spark:SetBlendMode("ADD")
	spark:SetAlpha(0.8)
	spark:SetPoint("TOPLEFT", bar:GetStatusBarTexture(), "TOPRIGHT", -10, 10)
	spark:SetPoint("BOTTOMRIGHT", bar:GetStatusBarTexture(), "BOTTOMRIGHT", 10, -10)

	local rest = CreateFrame("StatusBar", nil, bar)
	rest:SetAllPoints()
	rest:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	rest:SetStatusBarColor(1, 0, 1, 0.4)
	rest:SetFrameLevel(bar:GetFrameLevel() - 1)

	local reward = bar:CreateTexture(nil, "OVERLAY")
	reward:SetAtlas("ParagonReputation_Bag")
	reward:SetSize(12, 14)

	local text = bar:CreateFontString(nil, "OVERLAY")
	text:SetFontObject(SystemFont_Outline)
	text:SetShadowOffset(0, 0)
	text:SetWidth(bar:GetWidth() - 6)
	text:SetWordWrap(false)
	text:SetPoint("LEFT", bar, "RIGHT", -3, 0)
	text:SetPoint("RIGHT", bar, "LEFT", 3, 0)
	text:SetAlpha(0.8) -- Fade this a bit?

	ExperiencePlus.bar = bar
	bar.restBar = rest
	bar.reward = reward
	bar.text = text

	ExperiencePlus:SetupExpRepScript(bar)
	ExperiencePlus:ManageBarBubbles(bar)
	ExperiencePlus:ForceTextScaling(bar)
	ExperiencePlus.CreateMoverFrame(bar, nil, true)
	ExperiencePlus.RestoreMoverFrame(bar)
end
