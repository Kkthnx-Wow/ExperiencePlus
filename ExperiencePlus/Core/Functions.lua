local _, Functions = ...

local numberFormat, TempAnchor

Functions:RegisterOptionCallback("numberFormat", function(value)
	numberFormat = value
	if Functions.bar then
		Functions.OnExpBarEvent(Functions.bar)
	end
end)

-- Math
do
	-- Numberize
	function Functions.ShortValue(n)
		if numberFormat == 1 then
			if n >= 1e12 then
				return format("%.2ft", n / 1e12)
			elseif n >= 1e9 then
				return format("%.2fb", n / 1e9)
			elseif n >= 1e6 then
				return format("%.2fm", n / 1e6)
			elseif n >= 1e3 then
				return format("%.1fk", n / 1e3)
			else
				return format("%.0f", n)
			end
		elseif numberFormat == 2 then
			if n >= 1e12 then
				return format("%.2f" .. Functions.L["NumberCap3"], n / 1e12)
			elseif n >= 1e8 then
				return format("%.2f" .. Functions.L["NumberCap2"], n / 1e8)
			elseif n >= 1e4 then
				return format("%.1f" .. Functions.L["NumberCap1"], n / 1e4)
			else
				return format("%.0f", n)
			end
		else
			return format("%.0f", n)
		end
	end

	function Functions:Round(number, idp)
		idp = idp or 0
		local mult = 10 ^ idp
		return floor(number * mult + 0.5) / mult
	end
end

do
	function Functions.RGBToHex(r, g, b)
		if r then
			if type(r) == "table" then
				if r.r then
					r, g, b = r.r, r.g, r.b
				else
					r, g, b = unpack(r)
				end
			end
			return format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
		end
	end
end

-- Movable Frame
do
	function Functions:CreateMoverFrame(parent, saved)
		local frame = parent or self
		frame:SetMovable(true)
		frame:SetUserPlaced(true)
		frame:SetClampedToScreen(true)

		self:EnableMouse(true)
		self:RegisterForDrag("LeftButton")
		self:SetScript("OnDragStart", function()
			frame:StartMoving()
		end)
		self:SetScript("OnDragStop", function()
			frame:StopMovingOrSizing()
			if not saved then
				return
			end
			local orig, _, tar, x, y = frame:GetPoint()
			x, y = Functions:Round(x), Functions:Round(y)
			ExperiencePlusDB["tempanchor"][frame:GetName()] = { orig, "UIParent", tar, x, y }
		end)
	end

	function Functions:RestoreMoverFrame()
		local name = self:GetName()
		if name and ExperiencePlusDB and ExperiencePlusDB["tempanchor"] and ExperiencePlusDB["tempanchor"][name] then
			self:ClearAllPoints()
			self:SetPoint(unpack(ExperiencePlusDB["tempanchor"][name]))
			-- print("Restored position for " .. name .. " from database.")
		else
			-- Fallback: Set a default position if no saved position is found
			self:ClearAllPoints()
			self:SetPoint("TOP", UIParent, "TOP", 0, -6)
			print("No saved position found for " .. name .. ". Setting default position.")
		end
	end
end
