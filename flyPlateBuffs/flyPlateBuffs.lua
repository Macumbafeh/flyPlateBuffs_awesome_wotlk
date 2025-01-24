local AddonName, fPB = ...
L = fPB.L

local	C_NamePlate_GetNamePlateForUnit, C_NamePlate_GetNamePlates, CreateFrame, UnitDebuff, UnitBuff, UnitName, UnitIsUnit, UnitIsPlayer, UnitPlayerControlled, UnitIsEnemy, UnitIsFriend, GetSpellInfo, table_sort, strmatch, format, wipe, pairs, GetTime, math_floor =
		C_NamePlate.GetNamePlateForUnit, C_NamePlate.GetNamePlates, CreateFrame, UnitDebuff, UnitBuff, UnitName, UnitIsUnit, UnitIsPlayer, UnitPlayerControlled, UnitIsEnemy, UnitIsFriend, GetSpellInfo, table.sort, strmatch, format, wipe, pairs, GetTime, math.floor

local defaultSpells1, defaultSpells2 = fPB.defaultSpells1, fPB.defaultSpells2

local LSM = LibStub("LibSharedMedia-3.0")
fPB.LSM = LSM
local MSQ, Group

local config = LibStub("AceConfig-3.0")
local dialog = LibStub("AceConfigDialog-3.0")

fPB.db = {}
local db

local fPBMainOptions
local fPBSpellsList
local fPBProfilesOptions

fPB.chatColor = "|cFFFFA500"
fPB.linkColor = "|cff71d5ff"
local chatColor = fPB.chatColor
local linkColor = fPB.linkColor

local cachedSpells = {}
local PlatesBuffs = {}

local DefaultSettings = {
	profile = {
		showDebuffs = 2,		-- 1 = all, 2 = mine + spellList, 3 = only spellList, 4 = only mine, 5 = none
		showBuffs = 3,			-- 1 = all, 2 = mine + spellList, 3 = only spellList, 4 = only mine, 5 = none
		hidePermanent = true,
		notHideOnPersonalResource = true,

		showOnPlayers = true,
		showOnPets = true,
		showOnNPC = true,

		showOnEnemy = true,
		showOnFriend = true,
		showOnNeutral = true,

		showOnlyInCombat = false,
		showUnitInCombat = false,

		parentWorldFrame = false,

		baseWidth = 24,
		baseHeight = 24,
		myScale = 0.2,
		cropTexture = true,

		-- Buff Position Settings
        buffAnchorPoint = "BOTTOM",
        plateAnchorPointBuff = "TOP",
        xOffsetBuff = -63,
        yOffsetBuff = 45,

        -- Debuff Position Settings
        debuffAnchorPoint = "TOP",
        plateAnchorPointDebuff = "BOTTOM",
        xOffsetDebuff = -61,
        yOffsetDebuff = 73,
		
		xInterval = 3,
		yInterval = 6,
		
		buffPerLine = 5,
		numLines = 3,
		
		showStdCooldown = true,
		showStdSwipe = false,

		showDuration = true,
		showDecimals = true,
		durationPosition = 1, -- 1 - under, 2 - on icon, 3 - above icon
		font = "Friz Quadrata TT", --durationFont
		durationSize = 10,
		colorTransition = true,
		colorSingle = {1.0,1.0,1.0},

		stackPosition = 1,  -- 1 - on icon, 2 - under, 3 - above icon
		stackFont = "Friz Quadrata TT",
		stackSize = 10,
		stackColor = {1.0,1.0,1.0},

		blinkTimeleft = 0.2,

		borderStyle = 1,	-- 1 = \\texture\\border.tga, 2 = Blizzard, 3 = none
		colorizeBorder = true,
		colorTypes = {
			Magic 	= {0.20,0.60,1.00},
			Curse 	= {0.60,0.00,1.00},
			Disease = {0.60,0.40,0},
			Poison 	= {0.00,0.60,0},
			none 	= {0.80,0,   0},
			Buff 	= {0.00,1.00,0},
		},

		disableSort = false,
		sortMode = {
			"my", -- [1]
			"expiration", -- [2]
			"disable", -- [3]
			"disable", -- [4]
		},

		Spells = {},
		ignoredDefaultSpells = {},

		showSpellID = false,
		enableInterruptIcons = true,
		enableOpenIcons = false,
	},
}

local interruptDurations = {
   [26679] =  3, -- Deadly Throw
	[15752] = 10, -- Linken's Boomerang Disarm
    [19244] = 5, -- Spell Lock - Rank 1 (Warlock)
        [19647] = 6, -- Spell Lock - Rank 2 (Warlock)
    [8042] = 2, -- Earth Shock (Shaman)
        [8044] = 2,
        [8045] = 2,
        [8046] = 2,
        [10412] = 2,
        [10413] = 2,
        [10414] = 2,
        [25454] = 2,
    [13491] = 5, -- Iron Knuckles
    [16979] = 4, -- Feral Charge (Druid)
    [2139] = 8, -- Counterspell (Mage)
    [1766] = 5, -- Kick (Rogue)
        [1767] = 5,
        [1768] = 5,
        [1769] = 5,
        [38768] = 5,
    [32748] = 3, -- Deadly Throw
    [6554] = 4, -- Pummel
        [6552] = 4,
    [72] = 6, -- Shield Bash
        [1671] = 6,
        [1672] = 6,
        [29704] = 6,
    [22570] = 3, -- Maim
    [29443] = 10, -- Clutch of Foresight
}

-- Durations for your “open” AoE spells
local openSpellsDurations = {
    [26573] = 8,  -- Consecration
    [1543]  = 20, -- Flare
}

local activeInterrupts = {}
local activeOpenSpells = {}

do --add default spells
for i=1, #defaultSpells1 do
	local spellID = defaultSpells1[i]
	local name = GetSpellInfo(spellID)
	if name then
		DefaultSettings.profile.Spells[spellID] = {
			name = name,
			spellID = spellID,
			scale = 1,
			durationSize = 20, --seems like the player cant change this value ingame (the setting has no effect), so setting it here
			show = 1,	-- 1 = always, 2 = mine, 3 = never, 4 = on ally, 5 = on enemy
			stackSize = 16,
		}
	end
end

for i=1, #defaultSpells2 do
	local spellID = defaultSpells2[i]
	local name = GetSpellInfo(spellID)
	if name then
		DefaultSettings.profile.Spells[spellID] = {
			name = name,
			spellID = spellID,
			scale = 1,
			durationSize = 14,
			show = 1,	-- 1 = always, 2 = mine, 3 = never, 4 = on ally, 5 = on enemy
			stackSize = 14,
		}
	end
end

end

--timeIntervals
local minute, hour, day = 60, 3600, 86400
local aboutMinute, aboutHour, aboutDay = 59.5, 60 * 59.5, 3600 * 23.5

local function round(x) return floor(x + 0.5) end

local function FormatTime(seconds)
	if seconds < 5 and db.showDecimals then --this used to be 10 seconds(it still shows as "10" in the ingame options but im too lazy to edit it there so cba...
		return "%.1f", seconds
	elseif seconds < aboutMinute then
		local seconds = round(seconds)
		return seconds ~= 0 and seconds or ""
	elseif seconds < aboutHour then
		return "%dm", round(seconds/minute)
	elseif seconds < aboutDay then
		return "%dh", round(seconds/hour)
	else
		return "%dd", round(seconds/day)
	end
end

--custom reworked this shit to suit my needs, if you want the default green-->yellow-->red behavior, well... tough luck, get fucked
local function GetColorByTime(current, max)
    if max == 0 then max = 1 end
    local timeLeft = current
    local red, green, blue = 1, 1, 1  -- Default color: white

    if timeLeft < 10 then
        if timeLeft < 5 then
            if timeLeft < 1 then
                -- Red at 1 second or less
                red, green, blue = 1, 0, 0
            else
                -- Interpolate between yellow and red
                local t = (timeLeft - 1) / 4  -- Normalize between 1 and 5
                red = 1
                green = t  -- Decreases from 1 to 0
                blue = 0
            end
        else
            -- Interpolate between green and yellow
            local t = (10 - timeLeft) / 5  -- Normalize between 5 and 10
            red = t  -- Increases from 0 to 1
            green = 1
            blue = 0
        end
    end

    return red, green, blue
end



local function SortFunc(a,b)
	local i = 1
	while db.sortMode[i] do
		local mode, rev = db.sortMode[i],db.sortMode[i+0.5]
		if mode ~= "disable" and a[mode] ~= b[mode] then
			if mode == "my" and not rev then -- self first
				return (a.my and 1 or 0) > (b.my and 1 or 0)
			elseif mode == "my" and rev then
				return (a.my and 1 or 0) < (b.my and 1 or 0)
			elseif mode == "expiration" and not rev then
				return (a.expiration > 0 and a.expiration or 5000000) < (b.expiration > 0 and b.expiration or 5000000)
			elseif mode == "expiration" and rev then
				return (a.expiration > 0 and a.expiration or 5000000) > (b.expiration > 0 and b.expiration or 5000000)
			elseif (mode == "type" or mode == "scale") and not rev then
				return a[mode] > b[mode]
			else
				return a[mode] < b[mode]
			end
		end
		i = i+1
	end
end

local function DrawOnPlate(frame)
    if not (PlatesBuffs[frame].buffs[1] or PlatesBuffs[frame].debuffs[1]) then return end

    local maxWidth = 0
    local sumHeight = 0
    local buffIcons = frame.fPBiconsFrame.iconsFrame

    -- Helper function to layout icons
    local function LayoutIcons(iconList, positionSettings)
    local maxWidth = 0
    local sumHeight = 0

    for l = 1, db.numLines do
        local lineWidth = 0
        local lineHeight = 0

        for k = 1, db.buffPerLine do
            local index = (l - 1) * db.buffPerLine + k
            local icon = iconList[index]
            if not icon or not icon:IsShown() then break end
			
			-- Debugging: Print icon index and type
            -- print("Laying out icon index:", index, "Type:", icon.type)
			
            icon:ClearAllPoints()
            if l == 1 and k == 1 then
                -- First icon in the first line
                icon:SetPoint(positionSettings.buffAnchorPoint, frame.fPBiconsFrame, positionSettings.plateAnchorPointBuff, positionSettings.xOffsetBuff, positionSettings.yOffsetBuff)
            elseif k == 1 then
                -- First icon in subsequent lines
                local previousLineLastIcon = (l - 2) * db.buffPerLine + 1
                icon:SetPoint("BOTTOMLEFT", iconList[previousLineLastIcon], "TOPLEFT", 0, db.yInterval)
            else
                -- Icons within the same line
                icon:SetPoint("BOTTOMLEFT", iconList[index - 1], "BOTTOMRIGHT", db.xInterval, 0)
            end

            lineWidth = lineWidth + (icon.width or db.baseWidth) + db.xInterval
            lineHeight = math.max(icon.height or db.baseHeight, lineHeight)
        end
        maxWidth = math.max(maxWidth, lineWidth)
        sumHeight = sumHeight + lineHeight + db.yInterval
    end

    -- Set Frame Size
    frame.fPBiconsFrame:SetWidth(maxWidth - db.xInterval)
    frame.fPBiconsFrame:SetHeight(sumHeight - db.yInterval)
end


    -- Extract Buff Frames
    local buffCount = #PlatesBuffs[frame].buffs
    local buffFrames = {}
    for i = 1, buffCount do
        buffFrames[i] = buffIcons[i]
    end

    -- Layout Buffs
    LayoutIcons(buffFrames, {
        buffAnchorPoint = db.buffAnchorPoint,
        plateAnchorPointBuff = db.plateAnchorPointBuff,
        xOffsetBuff = db.xOffsetBuff,
        yOffsetBuff = db.yOffsetBuff,
    })

    -- Extract Debuff Frames
    local debuffCount = #PlatesBuffs[frame].debuffs
    local debuffFrames = {}
    for i = 1, debuffCount do
        debuffFrames[i] = buffIcons[buffCount + i]
    end

    -- Layout Debuffs with Debuff-specific Settings
    LayoutIcons(debuffFrames, {
        buffAnchorPoint = db.debuffAnchorPoint,
        plateAnchorPointBuff = db.plateAnchorPointDebuff,
        xOffsetBuff = db.xOffsetDebuff,
        yOffsetBuff = db.yOffsetDebuff,
    })

    -- Hide any extra icons beyond the current layout
    local totalIcons = buffCount + debuffCount
    for i = totalIcons + 1, #buffIcons do
        if buffIcons[i] then
            buffIcons[i]:Hide()
        end
    end

    -- Set Frame Position
    frame.fPBiconsFrame:ClearAllPoints()
    frame.fPBiconsFrame:SetPoint(db.buffAnchorPoint, frame, db.plateAnchorPoint, db.xOffset, db.yOffset)

    if MSQ then
        Group:ReSkin()
    end
end




local function AddBuff(frame, type, icon, stack, debufftype, duration, expiration, my, id, scale, durationSize, stackSize)
    if not PlatesBuffs[frame] then
        PlatesBuffs[frame] = {
            buffs = {},
            debuffs = {}
        }
    end

    local buffData = {
        type = type,
        icon = icon,
        stack = stack,
        debufftype = debufftype,
        duration = duration,
        expiration = expiration,
        scale = (my and db.myScale + 1 or 1) * (scale or 1),
        durationSize = durationSize,
        stackSize = stackSize,
        id = id,
    }

    if type == "HELPFUL" then
        table.insert(PlatesBuffs[frame].buffs, buffData)
    elseif type == "HARMFUL" then
        table.insert(PlatesBuffs[frame].debuffs, buffData)
    end
end


local function FilterBuffs(isAlly, frame, type, name, icon, stack, debufftype, duration, expiration, caster, spellID, id)
	if type == "HARMFUL" and db.showDebuffs == 5 then return end
	if type == "HELPFUL" and db.showBuffs == 5 then return end

	local Spells = db.Spells
	local listedSpell
	local my = caster == "player"
	local cachedID = cachedSpells[name]

	if Spells[spellID] and not db.ignoredDefaultSpells[spellID] then
		listedSpell = Spells[spellID]
	elseif cachedID then
		if cachedID == "noid" then
			listedSpell = Spells[name]
		else
			listedSpell = Spells[cachedID]
		end
	end

	-- showDebuffs  1 = all, 2 = mine + spellList, 3 = only spellList, 4 = only mine, 5 = none
	-- listedSpell.show  -- 1 = always, 2 = mine, 3 = never, 4 = on ally, 5 = on enemy
	if not listedSpell then
		if db.hidePermanent and duration == 0 then
			return
		end
		if (type == "HARMFUL" and (db.showDebuffs == 1 or ((db.showDebuffs == 2 or db.showDebuffs == 4) and my)))
		or (type == "HELPFUL"   and (db.showBuffs   == 1 or ((db.showBuffs   == 2 or db.showBuffs   == 4) and my))) then
			AddBuff(frame, type, icon, stack, debufftype, duration, expiration, my, id)
			return
		else
			return
		end
	else --listedSpell
		if (type == "HARMFUL" and (db.showDebuffs == 4 and not my))
		or (type == "HELPFUL" and (db.showBuffs == 4 and not my)) then
			return
		end
		if(listedSpell.show == 1)
		or(listedSpell.show == 2 and my)
		or(listedSpell.show == 4 and isAlly)
		or(listedSpell.show == 5 and not isAlly) then
			AddBuff(frame, type, icon, stack, debufftype, duration, expiration, my, id, listedSpell.scale, listedSpell.durationSize, listedSpell.stackSize)
			return
		end
	end
	
	local guid = UnitGUID(nameplateID)
    if guid and activeInterrupts[guid] then
        local intData = activeInterrupts[guid]
        local remaining = intData.expiration - GetTime()
        if remaining > 0 then
            -- We'll treat it like a "HARMFUL" debuff with an expiration.
            -- Use your normal 'AddBuff' or 'FilterBuffs' logic:
            AddBuff(
                frame,                  -- parent frame
                "HARMFUL",             -- auraType
                intData.icon,          -- icon
                1,                     -- stack
                nil,                   -- debuffType
                intData.duration,      -- duration
                intData.expiration,    -- expiration
                intData.isMine,        -- my? (optional)
                intData.spellID        -- ID
            )
        else
            -- It's expired; remove it
            activeInterrupts[guid] = nil
        end
    end
end

local function ScanUnitBuffs(nameplateID, frame)

    if PlatesBuffs[frame] then
        wipe(PlatesBuffs[frame].buffs)
        wipe(PlatesBuffs[frame].debuffs)
    else
        PlatesBuffs[frame] = {
            buffs = {},
            debuffs = {}
        }
    end

    local isAlly = UnitIsFriend(nameplateID, "player")
    local id = 1
    while UnitDebuff(nameplateID, id) do
        local name, rank, icon, stack, debufftype, duration, expiration, caster, _, _, spellID = UnitDebuff(nameplateID, id)
        FilterBuffs(isAlly, frame, "HARMFUL", name, icon, stack, debufftype, duration, expiration, caster, spellID, id)
        id = id + 1
    end

    id = 1
    while UnitBuff(nameplateID, id) do
        local name, rank, icon, stack, debufftype, duration, expiration, caster, _, _, spellID = UnitBuff(nameplateID, id)
        FilterBuffs(isAlly, frame, "HELPFUL", name, icon, stack, debufftype, duration, expiration, caster, spellID, id)
        id = id + 1
    end
	
	local guid = UnitGUID(nameplateID)
    if guid and activeInterrupts[guid] then
        local intData = activeInterrupts[guid]
        local remaining = intData.expiration - GetTime()
        if remaining > 0 then
            -- We'll treat it like a "HARMFUL" debuff with an expiration.
            -- Use your normal 'AddBuff' or 'FilterBuffs' logic:
            AddBuff(
                frame,                  -- parent frame
                "HARMFUL",             -- auraType
                intData.icon,          -- icon
                1,                     -- stack
                nil,                   -- debuffType
                intData.duration,      -- duration
                intData.expiration,    -- expiration
                intData.isMine,        -- my? (optional)
                intData.spellID        -- ID
            )
        else
            -- It's expired; remove it
            activeInterrupts[guid] = nil
        end
    end
	
	local guid = UnitGUID(nameplateID)
    
    -- check AoE table
    if guid and activeOpenSpells[guid] then
        local data = activeOpenSpells[guid]
        local remaining = data.expiration - GetTime()
        if remaining > 0 then
            -- Insert the fake aura
            AddBuff(
                frame,
                "HARMFUL",          -- or "HELPFUL" if you prefer
                data.icon,
                1,                  -- stack
                nil,                -- debuff type
                data.duration,
                data.expiration,
                data.isMine,
                data.spellID
            )
        else
            -- If time is up, remove it so we don’t keep displaying it
            activeOpenSpells[guid] = nil
        end
    end
end



local function FilterUnits(nameplateID)

	if db.showOnlyInCombat and not UnitAffectingCombat("player") then return true end -- InCombatLockdown()
	if db.showUnitInCombat and not UnitAffectingCombat(nameplateID) then return true end

	-- filter units
	if UnitIsUnit(nameplateID,"player") then return true end
	if UnitIsPlayer(nameplateID) and not db.showOnPlayers then return true end
	if UnitPlayerControlled(nameplateID) and not UnitIsPlayer(nameplateID) and not db.showOnPets then return true end
	if not UnitPlayerControlled(nameplateID) and not UnitIsPlayer(nameplateID) and not db.showOnNPC then return true end
	if UnitIsEnemy(nameplateID,"player") and not db.showOnEnemy then return true end
	if UnitIsFriend(nameplateID,"player") and not db.showOnFriend then return true end
	if not UnitIsFriend(nameplateID,"player") and not UnitIsEnemy(nameplateID,"player") and not db.showOnNeutral then return true end

	return false
end

local total = 0
local function iconOnUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.1 then return end -- only check ~10x/sec
    self.elapsed = 0

    if self.expiration and self.expiration > 0 then
        local timeLeft = self.expiration - GetTime()
        if timeLeft < 0 then
            -- Hide this icon entirely:
            self:SetAlpha(0)
            self:Hide()
            
            -- (Optional) remove it from the table so it doesn’t come back 
            -- next time LayoutIcons is called:
            local frame = self:GetParent():GetParent()  -- container is self:GetParent(), parent is nameplate
            local t = PlatesBuffs[frame].debuffs
            for i, auraData in ipairs(t) do
                if auraData.id == self.id then
                    table.remove(t, i)
                    break
                end
            end

            return
        end
			if db.showDuration then
				self.durationtext:SetFormattedText(FormatTime(timeLeft))
				if db.colorTransition then
					self.durationtext:SetTextColor(GetColorByTime(timeLeft,self.duration))
				end
				if db.durationPosition == 1 or db.durationPosition == 3 then
					self.durationBg:SetWidth(self.durationtext:GetStringWidth())
					self.durationBg:SetHeight(self.durationtext:GetStringHeight())
				end
			end
			if (timeLeft / (self.duration + 0.01) ) < db.blinkTimeleft and timeLeft < 60 then --buff only has 20% timeleft and is less then 60 seconds.
				local f = GetTime() % 1
				if f > 0.5 then
					f = 1 - f
				end
				self:SetAlpha(math.min(math.max(f * 3, 0), 1))
			end
		end
	end

local function GetTexCoordFromSize(frame,size,size2)
	local arg = size/size2
	local abj
	if arg > 1 then
		abj = 1/size*((size-size2)/2)

		frame:SetTexCoord(0 ,1,(0+abj),(1-abj))
	elseif arg < 1 then
		abj = 1/size2*((size2-size)/2)

		frame:SetTexCoord((0+abj),(1-abj),0,1)
	else
		frame:SetTexCoord(0, 1, 0, 1)
	end
end
local function UpdateBuffIcon(self)

	self:SetAlpha(1)
	self.stacktext:Hide()
	self.border:Hide()
	self.cooldown:Hide()
	self.durationtext:Hide()
	self.durationBg:Hide()
	self.stackBg:Hide()

	self:SetWidth(self.width)
	self:SetHeight(self.height)

	self.texture:SetTexture(self.icon)
	if db.cropTexture then
		GetTexCoordFromSize(self.texture,self.width,self.height)
	else
		self.texture:SetTexCoord(0, 1, 0, 1)
	end

	if db.borderStyle ~= 3 then
		local color
		if self.type == "HELPFUL" then
			color = db.colorTypes.Buff
		else
			if db.colorizeBorder then
				color = self.debufftype and db.colorTypes[self.debufftype] or db.colorTypes.none
			else
				color = db.colorTypes.none
			end
		end
		self.border:SetVertexColor(color[1], color[2], color[3])
		self.border:Show()
	end

	if db.showDuration and self.expiration > 0 then
		if db.durationPosition == 1 or db.durationPosition == 3 then
			self.durationtext:SetFont(fPB.font, (self.durationSize or db.durationSize), "THICKOUTLINE")
			self.durationBg:Show()
		else
			self.durationtext:SetFont(fPB.font, (self.durationSize or db.durationSize), "THICKOUTLINE")
		end
		self.durationtext:Show()
	end
	if self.stack > 1 then
		self.stacktext:SetText(tostring(self.stack))
		if db.stackPosition == 2 or db.stackPosition == 3 then
			self.stacktext:SetFont(fPB.stackFont, (self.stackSize or db.stackSize), "THICKOUTLINE")
			self.stackBg:SetWidth(self.stacktext:GetStringWidth())
			self.stackBg:SetHeight(self.stacktext:GetStringHeight())
			self.stackBg:Show()
		else
			self.stacktext:SetFont(fPB.stackFont, (self.stackSize or db.stackSize), "THICKOUTLINE")
		end
		self.stacktext:Show()
	end
end
local function UpdateBuffIconOptions(self)
	self.texture:SetAllPoints(self)

	self.border:SetAllPoints(self)
	if db.borderStyle == 1 then
		self.border:SetTexture("Interface\\Addons\\flyPlateBuffs\\texture\\border.tga")
		self.border:SetTexCoord(0.08,0.08, 0.08,0.92, 0.92,0.08, 0.92,0.92)		--хз почему отображает не на всю иконку по дефолту, цифры подбором
	elseif db.borderStyle == 2 then
		self.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
		self.border:SetTexCoord(0.296875,0.5703125,0,0.515625)		-- if "Interface\\Buttons\\UI-Debuff-Overlays"
	end

	if db.showDuration then
		self.durationtext:ClearAllPoints()
		self.durationBg:ClearAllPoints()
		if db.durationPosition == 1 then
			-- under icon
			self.durationtext:SetFont(fPB.font, (self.durationSize or db.durationSize), "NORMAL")
			self.durationtext:SetPoint("TOP", self, "BOTTOM", 0, -1)
			self.durationBg:SetPoint("CENTER", self.durationtext)
		elseif db.durationPosition == 3 then
			-- above icon
			self.durationtext:SetFont(fPB.font, (self.durationSize or db.durationSize), "NORMAL")
			self.durationtext:SetPoint("BOTTOM", self, "TOP", 0, 1)
			self.durationBg:SetPoint("CENTER", self.durationtext)
		else
			-- on icon
			self.durationtext:SetFont(fPB.font, (self.durationSize or db.durationSize), "OUTLINE")
			self.durationtext:SetPoint("CENTER", self, "CENTER", 0, 0)
		end
		if not colorTransition then
			self.durationtext:SetTextColor(db.colorSingle[1],db.colorSingle[2],db.colorSingle[3],1)
		end
	end

	self.stacktext:ClearAllPoints()
	self.stackBg:ClearAllPoints()
	self.stacktext:SetTextColor(db.stackColor[1],db.stackColor[2],db.stackColor[3],1)
	if db.stackPosition == 1 then
		-- on icon
		self.stacktext:SetFont(fPB.stackFont, (self.stackSize or db.stackSize), "OUTLINE")
		self.stacktext:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 3)
	elseif db.stackPosition == 2 then
		-- under icon
		self.stacktext:SetFont(fPB.stackFont, (self.stackSize or db.stackSize), "NORMAL")
		self.stacktext:SetPoint("TOP", self, "BOTTOM", 0, -1)
		self.stackBg:SetPoint("CENTER", self.stacktext)
	else
		-- above icon
		self.stacktext:SetFont(fPB.stackFont, (self.stackSize or db.stackSize), "NORMAL")
		self.stacktext:SetPoint("BOTTOM", self, "TOP", 0, 1)
		self.stackBg:SetPoint("CENTER", self.stacktext)
	end

		self:EnableMouse(false)

end
local function iconOnHide(self)
	self.stacktext:Hide()
	self.border:Hide()
	self.cooldown:Hide()
	self.durationtext:Hide()
	self.durationBg:Hide()
	self.stackBg:Hide()
end
local function CreateBuffIcon(frame, i)
    frame.fPBiconsFrame.iconsFrame[i] = CreateFrame("Button")
    frame.fPBiconsFrame.iconsFrame[i]:SetParent(frame.fPBiconsFrame)
    local buffIcon = frame.fPBiconsFrame.iconsFrame[i]

    buffIcon.texture = buffIcon:CreateTexture(nil, "BACKGROUND")
    buffIcon.border = buffIcon:CreateTexture(nil, "BORDER")
    buffIcon.cooldown = CreateFrame("Cooldown", nil, buffIcon, "CooldownFrameTemplate")
    buffIcon.cooldown:SetReverse(true)
    buffIcon.cooldown:SetDrawEdge(false)

    buffIcon.durationtext = buffIcon:CreateFontString(nil, "ARTWORK")
    buffIcon.durationBg = buffIcon:CreateTexture(nil, "BORDER")
    buffIcon.durationBg:SetVertexColor(0, 0, 0, .75)

    buffIcon.stacktext = buffIcon:CreateFontString(nil, "ARTWORK")
    buffIcon.stackBg = buffIcon:CreateTexture(nil, "BORDER")
    buffIcon.stackBg:SetVertexColor(0, 0, 0, .75)

    UpdateBuffIconOptions(buffIcon)

    buffIcon.stacktext:Hide()
    buffIcon.border:Hide()
    buffIcon.cooldown:Hide()
    buffIcon.durationtext:Hide()
    buffIcon.durationBg:Hide()
    buffIcon.stackBg:Hide()

    buffIcon:SetScript("OnHide", iconOnHide)
    buffIcon:SetScript("OnUpdate", iconOnUpdate)

    if MSQ then
        Group:AddButton(buffIcon, {
            Icon = buffIcon.texture,
            Cooldown = buffIcon.cooldown,
            Normal = buffIcon.border,
            Count = false,
            Duration = false,
            FloatingBG = false,
            Flash = false,
            Pushed = false,
            Disabled = false,
            Checked = false,
            Border = false,
            AutoCastable = false,
            Highlight = false,
            HotKey = false,
            Name = false,
            AutoCast = false,
        })
    end
end


local function UpdateUnitAuras(nameplateID, updateOptions)
    local frame = C_NamePlate_GetNamePlateForUnit(nameplateID)
    if not frame then return end -- Modifying friendly nameplates is restricted in instances since 7.2

    if FilterUnits(nameplateID) then
        if frame.fPBiconsFrame then
            frame.fPBiconsFrame:Hide()
        end
        return
    end

    ScanUnitBuffs(nameplateID, frame)
    if not PlatesBuffs[frame] then
        if frame.fPBiconsFrame then
            frame.fPBiconsFrame:Hide()
        end
        return
    end
    if not db.disableSort then
        table_sort(PlatesBuffs[frame].buffs, SortFunc)
        table_sort(PlatesBuffs[frame].debuffs, SortFunc)
    end

    if not frame.fPBiconsFrame then
        -- If parent == frame then it will change scale and alpha with nameplates
        -- Otherwise use UIParent, but this causes mess of icon/border textures
        frame.fPBiconsFrame = CreateFrame("Frame")
        local parent = db.parentWorldFrame and WorldFrame or frame
        frame.fPBiconsFrame:SetParent(parent)
    end
    if not frame.fPBiconsFrame.iconsFrame then
        frame.fPBiconsFrame.iconsFrame = {}
    end

    -- Create icons for buffs
    for i = 1, #PlatesBuffs[frame].buffs do
        if not frame.fPBiconsFrame.iconsFrame[i] then
            CreateBuffIcon(frame, i)
        end

        local buff = PlatesBuffs[frame].buffs[i]
        local buffIcon = frame.fPBiconsFrame.iconsFrame[i]
        buffIcon.type = buff.type
        buffIcon.icon = buff.icon
        buffIcon.stack = buff.stack
        buffIcon.debufftype = buff.debufftype
        buffIcon.duration = buff.duration
        buffIcon.expiration = buff.expiration
        buffIcon.id = buff.id
        buffIcon.durationSize = buff.durationSize
        buffIcon.stackSize = buff.stackSize
        buffIcon.width = db.baseWidth * buff.scale
        buffIcon.height = db.baseHeight * buff.scale
        if updateOptions then
            UpdateBuffIconOptions(buffIcon)
        end
        UpdateBuffIcon(buffIcon)
        buffIcon:Show()
    end

    -- Create icons for debuffs
    local debuffStartIndex = #PlatesBuffs[frame].buffs + 1
    for i = 1, #PlatesBuffs[frame].debuffs do
        local index = debuffStartIndex + i - 1
        if not frame.fPBiconsFrame.iconsFrame[index] then
            CreateBuffIcon(frame, index)
        end

        local debuff = PlatesBuffs[frame].debuffs[i]
        local debuffIcon = frame.fPBiconsFrame.iconsFrame[index]
        debuffIcon.type = debuff.type
        debuffIcon.icon = debuff.icon
        debuffIcon.stack = debuff.stack
        debuffIcon.debufftype = debuff.debufftype
        debuffIcon.duration = debuff.duration
        debuffIcon.expiration = debuff.expiration
        debuffIcon.id = debuff.id
        debuffIcon.durationSize = debuff.durationSize
        debuffIcon.stackSize = debuff.stackSize
        debuffIcon.width = db.baseWidth * debuff.scale
        debuffIcon.height = db.baseHeight * debuff.scale
        if updateOptions then
            UpdateBuffIconOptions(debuffIcon)
        end
        UpdateBuffIcon(debuffIcon)
        debuffIcon:Show()
    end
    frame.fPBiconsFrame:Show()

    -- Hide any extra icons beyond the current layout
    local totalIcons = #PlatesBuffs[frame].buffs + #PlatesBuffs[frame].debuffs
    for i = totalIcons + 1, #frame.fPBiconsFrame.iconsFrame do
        if frame.fPBiconsFrame.iconsFrame[i] then
            frame.fPBiconsFrame.iconsFrame[i]:Hide()
        end
    end

    DrawOnPlate(frame)
end



function fPB.UpdateAllNameplates(updateOptions)
	for i, p in ipairs(C_NamePlate_GetNamePlates()) do
		local unit = p.namePlateUnitToken
		if unit then
			
			UpdateUnitAuras(unit,updateOptions)
		end
	end
end
local UpdateAllNameplates = fPB.UpdateAllNameplates

local function Nameplate_Added(...)
	local nameplateID = ...
	local frame = C_NamePlate_GetNamePlateForUnit(nameplateID)
	if frame then frame.namePlateUnitToken = nameplateID end
	if frame and frame.BuffFrame then
		if db.notHideOnPersonalResource and UnitIsUnit(nameplateID,"player") then
			frame.BuffFrame:SetAlpha(1)
		else
			frame.BuffFrame:SetAlpha(0)	--Hide terrible standart debuff frame
		end
	end

	UpdateUnitAuras(nameplateID)
end
local function Nameplate_Removed(...)
	local nameplateID = ...
	local frame = C_NamePlate_GetNamePlateForUnit(nameplateID)

	if frame.fPBiconsFrame then
		frame.fPBiconsFrame:Hide()
	end
	if PlatesBuffs[frame] then
		PlatesBuffs[frame] = nil
	end
	
	local guid = UnitGUID(nameplateID)
        if guid then
            activeInterrupts[guid] = nil
        end
end

local function FixSpells()
	for spell,s in pairs(db.Spells) do
		if not s.name then
			local name
			local spellID = tonumber(spell) and tonumber(spell) or spell.spellID
			if spellID then
				name = GetSpellInfo(spellID)
			else
				name = tostring(spell)
			end
			db.Spells[spell].name = name
		end
	end
end
function fPB.CacheSpells() -- spells filtered by names, not checking id
	cachedSpells = {}
	for spell,s in pairs(db.Spells) do
		if not s.checkID and not db.ignoredDefaultSpells[spell] and s.name then
			if s.spellID then
				cachedSpells[s.name] = s.spellID
			else
				cachedSpells[s.name] = "noid"
			end
		end
	end
end
local CacheSpells = fPB.CacheSpells

function fPB.AddNewSpell(spell)
	local defaultSpell
	if db.ignoredDefaultSpells[spell] then
		db.ignoredDefaultSpells[spell] = nil
		defaultSpell = true
	end
	local spellID = tonumber(spell)
	if db.Spells[spell] and not defaultSpell then
		if spellID then
			DEFAULT_CHAT_FRAME:AddMessage(chatColor..L["Spell with this ID is already in the list. Its name is "]..linkColor.."|Hspell:"..spellID.."|h["..GetSpellInfo(spellID).."]|h|r")
			return
		else
			DEFAULT_CHAT_FRAME:AddMessage(spell..chatColor..L[" already in the list."].."|r")
			return
		end
	end
	local name = GetSpellInfo(spellID)
	if spellID and name then
		if not db.Spells[spellID] then
			db.Spells[spellID] = {
				show = 1,
				name = name,
				spellID = spellID,
				scale = 1,
				stackSize = db.stackSize,
				durationSize = db.durationSize,
			}
		end
	else
		db.Spells[spell] = {
			show = 1,
			name = spell,
			scale = 1,
			stackSize = db.stackSize,
			durationSize = db.durationSize,
		}
	end

	CacheSpells()
	fPB.BuildSpellList()
	UpdateAllNameplates(true)
end
function fPB.RemoveSpell(spell)
	if DefaultSettings.profile.Spells[spell] then
		db.ignoredDefaultSpells[spell] = true
	end
	db.Spells[spell] = nil
	CacheSpells()
	fPB.BuildSpellList()
	UpdateAllNameplates(true)
end
function fPB.ChangeSpellID(oldID, newID)
	if db.Spells[newID] then
		DEFAULT_CHAT_FRAME:AddMessage(chatColor..L["Spell with this ID is already in the list. Its name is "]..linkColor.."|Hspell:"..newID.."|h["..GetSpellInfo(newID).."]|h|r")
		return
	end
	db.Spells[newID] = {}
	for k,v in pairs(db.Spells[oldID]) do
		db.Spells[newID][k] = v
		db.Spells[newID].spellID = newID
	end
	fPB.RemoveSpell(oldID)
	DEFAULT_CHAT_FRAME:AddMessage(GetSpellInfo(newID)..chatColor..L[" ID changed "].."|r"..(tonumber(oldID) or "nil")..chatColor.." -> |r"..newID)
	UpdateAllNameplates(true)
	fPB.BuildSpellList()
end

local function ConvertDBto2()
	local temp
	for _,p in pairs(flyPlateBuffsDB.profiles) do
		if p.Spells then
			temp = {}
			for n,s in pairs(p.Spells) do
				local spellID = s.spellID
				if not spellID then
					for i=1, #defaultSpells1 do
						if n == GetSpellInfo(defaultSpells1[i]) then
							spellID = defaultSpells1[i]
							break
						end
					end
				end
				if not spellID then
					for i=1, #defaultSpells2 do
						if n == GetSpellInfo(defaultSpells2[i]) then
							spellID = defaultSpells2[i]
							break
						end
					end
				end
				local spell = spellID and spellID or n
				if spell then
					temp[spell] = {}
					for k,v in pairs(s) do
						temp[spell][k] = v
					end
					temp[spell].name = GetSpellInfo(spellID) and GetSpellInfo(spellID) or n
				end
			end
			p.Spells = temp
			temp = nil
		end
		if p.ignoredDefaultSpells then
			temp = {}
			for n,v in pairs(p.ignoredDefaultSpells) do
				local spellID
				for i=1, #defaultSpells1 do
					if n == GetSpellInfo(defaultSpells1[i]) then
						spellID = defaultSpells1[i]
						break
					end
				end
				if not spellID then
					for i=1, #defaultSpells2 do
						if n == GetSpellInfo(defaultSpells2[i]) then
							spellID = defaultSpells2[i]
							break
						end
					end
				end
				if spellID then
					temp[spellID] = true
				end
			end
			p.ignoredDefaultSpells = temp
			temp = nil
		end
	end
	flyPlateBuffsDB.version = 2
end
function fPB.OnProfileChanged()
	db = fPB.db.profile
	fPB.OptionsOnEnable()
	UpdateAllNameplates(true)
end
local function Initialize()
	if flyPlateBuffsDB and (not flyPlateBuffsDB.version or flyPlateBuffsDB.version < 2) then
		ConvertDBto2()
	end

	fPB.db = LibStub("AceDB-3.0"):New("flyPlateBuffsDB", DefaultSettings, true)
	fPB.db.RegisterCallback(fPB, "OnProfileChanged", "OnProfileChanged")
	fPB.db.RegisterCallback(fPB, "OnProfileCopied", "OnProfileChanged")
	fPB.db.RegisterCallback(fPB, "OnProfileReset", "OnProfileChanged")

	db = fPB.db.profile
	fPB.font = fPB.LSM:Fetch("font", db.font)
	fPB.stackFont = fPB.LSM:Fetch("font", db.stackFont)
	FixSpells()
	CacheSpells()

	config:RegisterOptionsTable(AddonName, fPB.MainOptionTable)
	fPBMainOptions = dialog:AddToBlizOptions(AddonName, AddonName)

	config:RegisterOptionsTable(AddonName.." Spells", fPB.SpellsTable)
	fPBSpellsList = dialog:AddToBlizOptions(AddonName.." Spells", L["Specific spells"], AddonName)

	config:RegisterOptionsTable(AddonName.." Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(fPB.db))
	fPBProfilesOptions = dialog:AddToBlizOptions(AddonName.." Profiles", L["Profiles"], AddonName)

	SLASH_FLYPLATEBUFFS1, SLASH_FLYPLATEBUFFS2 = "/fpb", "/pb"
	function SlashCmdList.FLYPLATEBUFFS(msg, editBox)
		InterfaceOptionsFrame_OpenToCategory(fPBMainOptions)
		InterfaceOptionsFrame_OpenToCategory(fPBSpellsList)
		InterfaceOptionsFrame_OpenToCategory(fPBMainOptions)
	end
end

function fPB.RegisterCombat()
	fPB.Events:RegisterEvent("PLAYER_REGEN_DISABLED")
	fPB.Events:RegisterEvent("PLAYER_REGEN_ENABLED")
end
function fPB.UnregisterCombat()
	fPB.Events:UnregisterEvent("PLAYER_REGEN_DISABLED")
	fPB.Events:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

fPB.Events = CreateFrame("Frame")
fPB.Events:RegisterEvent("ADDON_LOADED")
fPB.Events:RegisterEvent("PLAYER_LOGIN")
fPB.Events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
fPB.Events:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and (...) == AddonName then
		Initialize()
	elseif event == "PLAYER_LOGIN" then
		fPB.OptionsOnEnable()
		if db.showSpellID then fPB.ShowSpellID() end
		MSQ = LibStub("Masque", true)
		if MSQ then
			Group = MSQ:Group(AddonName)
			MSQ:Register(AddonName, function(addon, group, skinId, gloss, backdrop, colors, disabled)
				if disabled then
					UpdateAllNameplates(true)
				end
			end)
		end

		fPB.Events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		fPB.Events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

		if db.showOnlyInCombat then
			fPB.RegisterCombat()
		else
			fPB.Events:RegisterEvent("UNIT_AURA")
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		fPB.Events:RegisterEvent("UNIT_AURA")
		UpdateAllNameplates()
	elseif event == "PLAYER_REGEN_ENABLED" then
		fPB.Events:UnregisterEvent("UNIT_AURA")
		UpdateAllNameplates()
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, event, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo(...)


        if db.enableInterruptIcons and event == "SPELL_INTERRUPT" then
		-- print("DEBUG: We got SPELL_INTERRUPT!", spellID, spellName, "destGUID=", destGUID)
    
            local duration = interruptDurations[spellID] or 4
            local now = GetTime()
            local icon = select(3, GetSpellInfo(spellID)) or "Interface\\Icons\\INV_Misc_QuestionMark"

            -- Mark that the destGUID is 'locked out' until now + duration:
            activeInterrupts[destGUID] = {
                spellID    = spellID,
                icon       = icon,
                start      = now,
                expiration = now + duration,
                duration   = duration,
                isMine     = (sourceGUID == UnitGUID("player")),  -- optional
            }

            -- Force an update if that nameplate is visible:
            for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
                local unit = plate.namePlateUnitToken
                if unit and UnitGUID(unit) == destGUID then
                    UpdateUnitAuras(unit)  -- cause a refresh
                end
            end
		elseif db.enableOpenIcons and event == "SPELL_CAST_SUCCESS" and (spellID == 26573 or spellID == 1543) then
		 -- print("DEBUG: We got SPELL_CAST_SUCCESS!", spellID, spellName, "from", sourceGUID)
			
			local duration = openSpellsDurations[spellID] or 4
			local now      = GetTime()
			local icon     = select(3, GetSpellInfo(spellID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
			-- Store the “fake aura” in our activeOpenSpells table, keyed by the caster’s GUID
			activeOpenSpells[sourceGUID] = {
				spellID    = spellID,
				icon       = icon,
				start      = now,
				expiration = now + duration,
				duration   = duration,
				isMine     = (sourceGUID == UnitGUID("player")),
			}
			-- Force an update if that caster's nameplate is visible
			for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
				local unit = plate.namePlateUnitToken
				if unit and UnitGUID(unit) == sourceGUID then
					UpdateUnitAuras(unit)  -- cause a refresh
				end
			end
        end
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		Nameplate_Added(...)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		Nameplate_Removed(...)
	elseif event == "UNIT_AURA" then
		if ... and strmatch((...),"nameplate%d+") then
			UpdateUnitAuras(...)
		end
	end
end)
