--------------------------------------------------------------------------
--  flyPlateBuffs for WoW 3.3.5 or Classic - Two-Container Rewritten
--  This version splits the icons into buff vs. debuff frames, so buffs
--  do not move when new debuffs appear.
--------------------------------------------------------------------------

local AddonName, fPB = ...
local L = fPB.L

--------------------------------------------------------------------------
--  Local references
--------------------------------------------------------------------------
local C_NamePlate_GetNamePlateForUnit, C_NamePlate_GetNamePlates = C_NamePlate.GetNamePlateForUnit, C_NamePlate.GetNamePlates
local CreateFrame, UnitDebuff, UnitBuff, UnitName, UnitIsUnit = CreateFrame, UnitDebuff, UnitBuff, UnitName, UnitIsUnit
local UnitIsPlayer, UnitPlayerControlled, UnitIsEnemy, UnitIsFriend = UnitIsPlayer, UnitPlayerControlled, UnitIsEnemy, UnitIsFriend
local GetSpellInfo, table_sort, strmatch, format, wipe, pairs, GetTime = GetSpellInfo, table.sort, strmatch, format, wipe, pairs, GetTime
local math_floor = math.floor

-- references to your default table arrays
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

--------------------------------------------------------------------------
--  Data structures
--------------------------------------------------------------------------
local cachedSpells = {}
local PlatesBuffs = {}

--------------------------------------------------------------------------
--  DefaultSettings
--------------------------------------------------------------------------
local DefaultSettings = {
	profile = {
		showDebuffs = 2,
		showBuffs   = 3,
		hidePermanent = true,
		notHideOnPersonalResource = true,

		showOnPlayers = true,
		showOnPets    = true,
		showOnNPC     = true,
		showOnEnemy   = true,
		showOnFriend  = true,
		showOnNeutral = true,

		showOnlyInCombat = false,
		showUnitInCombat = false,

		parentWorldFrame = false,

		baseWidth  = 24,
		baseHeight = 24,
		myScale    = 0.2,
		cropTexture= true,

		-- Buff Position
		buffAnchorPoint      = "BOTTOM",
		plateAnchorPointBuff = "TOP",
		xOffsetBuff          = -63,
		yOffsetBuff          = 45,

		-- Debuff Position
		debuffAnchorPoint      = "TOP",
		plateAnchorPointDebuff = "BOTTOM",
		xOffsetDebuff          = -61,
		yOffsetDebuff          = 73,

		xInterval = 3,
		yInterval = 6,
		
		buffPerLine = 5,
		numLines    = 3,

		showStdCooldown = true,
		showStdSwipe    = false,

		showDuration    = true,
		showDecimals    = true,
		durationPosition= 1,
		font            = "Friz Quadrata TT",
		durationSize    = 10,
		colorTransition = true,
		colorSingle     = {1,1,1},

		stackPosition   = 1,
		stackFont       = "Friz Quadrata TT",
		stackSize       = 10,
		stackColor      = {1,1,1},

		blinkTimeleft   = 0.2,

		borderStyle     = 1,
		colorizeBorder  = true,
		colorTypes = {
			Magic   = {0.20,0.60,1.00},
			Curse   = {0.60,0.00,1.00},
			Disease = {0.60,0.40,0},
			Poison  = {0.00,0.60,0},
			none    = {0.80,0,0},
			Buff    = {0.00,1.00,0},
		},

		disableSort = false,
		sortMode = {
			"my","expiration","disable","disable"
		},

		Spells = {},
		ignoredDefaultSpells = {},
		showSpellID = false,
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

local activeInterrupts = {}

-- Add default spells from defaultSpells1, defaultSpells2 ...
do
	--  as your code
	for i=1, #defaultSpells1 do
		local sid = defaultSpells1[i]
		local sName = GetSpellInfo(sid)
		if sName then
			DefaultSettings.profile.Spells[sid] = {
				name         = sName,
				spellID      = sid,
				scale        = 1,
				durationSize = 20,
				show         = 1,
				stackSize    = 16,
			}
		end
	end
	for i=1, #defaultSpells2 do
		local sid = defaultSpells2[i]
		local sName = GetSpellInfo(sid)
		if sName then
			DefaultSettings.profile.Spells[sid] = {
				name         = sName,
				spellID      = sid,
				scale        = 1,
				durationSize = 14,
				show         = 1,
				stackSize    = 14,
			}
		end
	end
end

--------------------------------------------------------------------------
--  Helpers
--------------------------------------------------------------------------
local function round(x) return math_floor(x + 0.5) end

local function FormatTime(seconds)
	--  code as your existing FormatTime
	if db.showDecimals and seconds < 5 then
		return "%.1f", seconds
	end
	local minute, hour, day = 60, 3600, 86400
	if seconds < 59.5 then
		local s = round(seconds)
		return s ~= 0 and s or ""
	elseif seconds < 3600*23.5 then
		if seconds < 3600 then
			return "%dm", round(seconds/60)
		else
			return "%dh", round(seconds/3600)
		end
	else
		return "%dd", round(seconds/86400)
	end
end

local function GetColorByTime(current, max)
	--  code as your existing function
	if max==0 then max=1 end
	local timeLeft = current
	local r,g,b = 1,1,1
	if timeLeft < 10 then
		if timeLeft < 5 then
			if timeLeft < 1 then
				r,g,b = 1,0,0
			else
				local t = (timeLeft -1)/4
				r=1; g=t; b=0
			end
		else
			local t = (10-timeLeft)/5
			r= t; g=1; b=0
		end
	end
	return r,g,b
end

--------------------------------------------------------------------------
--  Sorting
--------------------------------------------------------------------------
local function SortFunc(a,b)
	--  code as your existing SortFunc
	local i=1
	while db.sortMode[i] do
		local mode, rev = db.sortMode[i], db.sortMode[i+0.5]
		if mode~="disable" and a[mode]~=b[mode] then
			if mode=="my" and not rev then
				return (a.my and 1 or 0) > (b.my and 1 or 0)
			elseif mode=="my" and rev then
				return (a.my and 1 or 0) < (b.my and 1 or 0)
			elseif mode=="expiration" and not rev then
				local aExp= (a.expiration>0 and a.expiration or 999999)
				local bExp= (b.expiration>0 and b.expiration or 999999)
				return aExp < bExp
			elseif mode=="expiration" and rev then
				local aExp= (a.expiration>0 and a.expiration or 999999)
				local bExp= (b.expiration>0 and b.expiration or 999999)
				return aExp > bExp
			elseif (mode=="type" or mode=="scale") and not rev then
				return a[mode]>b[mode]
			else
				return a[mode]<b[mode]
			end
		end
		i=i+1
	end
end

--------------------------------------------------------------------------
--  The container-based layout function
--------------------------------------------------------------------------
-- We'll place all icons in lines, just like you do in DrawOnPlate or LayoutIcons.
-- But it will ONLY be for the container passed in (Buffs or Debuffs).
local function LayoutIcons(containerFrame, icons, isBuff)
	local maxWidth = 0
	local sumHeight=0

	local count = #icons
	local index = 1

	for l=1, db.numLines do
		local lineWidth=0
		local lineHeight=0
		for k=1, db.buffPerLine do
			local icon = icons[index]
			if not icon or not icon:IsShown() then
				break
			end
			icon:ClearAllPoints()
			if l==1 and k==1 then
				-- first icon in first line
				icon:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 0, 0)
			elseif k==1 then
				-- first icon in subsequent lines
				local iconAbove = icons[index - db.buffPerLine]
				if iconAbove then
					icon:SetPoint("BOTTOMLEFT", iconAbove, "TOPLEFT", 0, db.yInterval)
				end
			else
				local iconLeft = icons[index -1]
				icon:SetPoint("BOTTOMLEFT", iconLeft, "BOTTOMRIGHT", db.xInterval, 0)
			end
			lineWidth = lineWidth + (icon.width or db.baseWidth) + db.xInterval
			lineHeight= math.max(lineHeight, icon.height or db.baseHeight)
			index=index+1
			if index>count then
				break
			end
		end
		maxWidth  = math.max(maxWidth, lineWidth)
		sumHeight = sumHeight + lineHeight + db.yInterval
		if index>count then
			break
		end
	end
	if sumHeight>0 then
		sumHeight= sumHeight - db.yInterval
	end
	if maxWidth>0 then
		maxWidth= maxWidth - db.xInterval
	end
	containerFrame:SetSize(maxWidth, sumHeight)
end

--------------------------------------------------------------------------
--  Data: AddBuff, FilterBuffs, ScanUnitBuffs
--------------------------------------------------------------------------
local function AddBuff(frame, auraType, icon, stack, debufftype, duration, expiration, my, id, scale, durationSize, stackSize)
	if not PlatesBuffs[frame] then
		PlatesBuffs[frame] = { buffs={}, debuffs={} }
	end
	local buffData = {
		type = auraType,
		icon = icon,
		stack= stack,
		debufftype = debufftype,
		duration= duration,
		expiration= expiration,
		scale= (my and db.myScale+1 or 1)*(scale or 1),
		durationSize= durationSize,
		stackSize= stackSize,
		id= id,
		my= my,
	}

	if auraType=="HELPFUL" then
		table.insert(PlatesBuffs[frame].buffs, buffData)
	elseif auraType=="HARMFUL" then
		table.insert(PlatesBuffs[frame].debuffs, buffData)
	end
end

local function FilterBuffs(isAlly, frame, auraType, name, icon, stack, debufftype, duration, expiration, caster, spellID, id)
	if auraType=="HARMFUL" and db.showDebuffs==5 then return end
	if auraType=="HELPFUL" and db.showBuffs==5 then return end

	local Spells= db.Spells
	local listedSpell
	local my= (caster=="player")
	local cachedID= cachedSpells[name]

	if Spells[spellID] and not db.ignoredDefaultSpells[spellID] then
		listedSpell= Spells[spellID]
	elseif cachedID then
		if cachedID=="noid" then
			listedSpell= Spells[name]
		else
			listedSpell= Spells[cachedID]
		end
	end

	if not listedSpell then
		if db.hidePermanent and duration==0 then
			return
		end
		if (auraType=="HARMFUL" and (db.showDebuffs==1 or((db.showDebuffs==2 or db.showDebuffs==4)and my)))
		or  (auraType=="HELPFUL" and (db.showBuffs==1 or((db.showBuffs==2 or db.showBuffs==4)and my))) then
			AddBuff(frame, auraType, icon, stack, debufftype, duration, expiration, my, id)
		end
	else
		if (auraType=="HARMFUL" and db.showDebuffs==4 and not my) 
		or  (auraType=="HELPFUL" and db.showBuffs==4 and not my) then
			return
		end
		if (listedSpell.show==1) 
		or  (listedSpell.show==2 and my)
		or  (listedSpell.show==4 and isAlly)
		or  (listedSpell.show==5 and not isAlly) then
			AddBuff(frame, auraType, icon, stack, debufftype, duration, expiration, my, id, listedSpell.scale, listedSpell.durationSize, listedSpell.stackSize)
		end
	end
end

local function ScanUnitBuffs(nameplateID, frame)
	if PlatesBuffs[frame] then
		wipe(PlatesBuffs[frame].buffs)
		wipe(PlatesBuffs[frame].debuffs)
	else
		PlatesBuffs[frame] = { buffs={}, debuffs={} }
	end

	local isAlly= UnitIsFriend(nameplateID,"player")
	local i=1
	while true do
		local name, _, icon, stack, debufftype, duration, expiration, caster, _,_, spellID = UnitDebuff(nameplateID, i)
		if not name then break end
		FilterBuffs(isAlly, frame, "HARMFUL", name, icon, stack, debufftype, duration, expiration, caster, spellID, i)
		i=i+1
	end

	i=1
	while true do
		local name, _, icon, stack, debufftype, duration, expiration, caster, _,_, spellID = UnitBuff(nameplateID, i)
		if not name then break end
		FilterBuffs(isAlly, frame, "HELPFUL", name, icon, stack, debufftype, duration, expiration, caster, spellID, i)
		i=i+1
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

--------------------------------------------------------------------------
--  FilterUnits
--------------------------------------------------------------------------
local function FilterUnits(nameplateID)
	if db.showOnlyInCombat and not UnitAffectingCombat("player") then
		return true
	end
	if db.showUnitInCombat and not UnitAffectingCombat(nameplateID) then
		return true
	end
	if UnitIsUnit(nameplateID,"player") then
		return true
	end
	if UnitIsPlayer(nameplateID) and not db.showOnPlayers then
		return true
	end
	if UnitPlayerControlled(nameplateID) and not UnitIsPlayer(nameplateID) and not db.showOnPets then
		return true
	end
	if not UnitPlayerControlled(nameplateID) and not UnitIsPlayer(nameplateID) and not db.showOnNPC then
		return true
	end
	if UnitIsEnemy(nameplateID,"player") and not db.showOnEnemy then
		return true
	end
	if UnitIsFriend(nameplateID,"player") and not db.showOnFriend then
		return true
	end
	if not UnitIsFriend(nameplateID,"player") and not UnitIsEnemy(nameplateID,"player") and not db.showOnNeutral then
		return true
	end
	return false
end

--------------------------------------------------------------------------
--  Icon OnUpdate, etc.
--------------------------------------------------------------------------
local total=0
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
				local fmt, val = FormatTime(timeLeft)
				self.durationtext:SetFormattedText(fmt, val)
				if db.colorTransition then
					local r,g,b= GetColorByTime(timeLeft, self.duration)
					self.durationtext:SetTextColor(r,g,b,1)
				end
				if db.durationPosition==1 or db.durationPosition==3 then
					self.durationBg:SetWidth(self.durationtext:GetStringWidth())
					self.durationBg:SetHeight(self.durationtext:GetStringHeight())
				end
			end
			if (timeLeft/(self.duration+0.01))<db.blinkTimeleft and timeLeft<60 then
				local f= GetTime()%1
				if f>0.5 then f=1-f end
				self:SetAlpha(math.min(math.max(f*3,0),1))
			end
		end
	end

local function iconOnHide(self)
	self.stacktext:Hide()
	self.border:Hide()
	self.cooldown:Hide()
	self.durationtext:Hide()
	self.durationBg:Hide()
	self.stackBg:Hide()
end

local function GetTexCoordFromSize(frame, width, height)
	local ratio= width/height
	if ratio>1 then
		local excess= (1-(height/width))/2
		frame:SetTexCoord(0,1,excess,1-excess)
	elseif ratio<1 then
		local excess= (1-(width/height))/2
		frame:SetTexCoord(excess,1-excess,0,1)
	else
		frame:SetTexCoord(0,1,0,1)
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
		GetTexCoordFromSize(self.texture, self.width, self.height)
	else
		self.texture:SetTexCoord(0,1,0,1)
	end

	if db.borderStyle~=3 then
		local color
		if self.type=="HELPFUL" then
			color= db.colorTypes.Buff
		else
			if db.colorizeBorder then
				color= self.debufftype and db.colorTypes[self.debufftype] or db.colorTypes.none
			else
				color= db.colorTypes.none
			end
		end
		if color then
			self.border:SetVertexColor(color[1],color[2],color[3])
			self.border:Show()
		end
	end

	if db.showDuration and self.expiration>0 then
		if db.durationPosition==1 or db.durationPosition==3 then
			self.durationtext:SetFont(fPB.font, (self.durationSize or db.durationSize), "NORMAL")
			self.durationBg:Show()
		else
			self.durationtext:SetFont(fPB.font, (self.durationSize or db.durationSize), "OUTLINE")
		end
		self.durationtext:Show()
	end

	if self.stack>1 then
		if not self.stacktext:GetFont() then
		-- Use your LSM-queried font or a fallback
		self.stacktext:SetFont(fPB.stackFont or "Fonts\\FRIZQT__.TTF",
                           (self.stackSize or db.stackSize),
                           "OUTLINE")
		end
		self.stacktext:SetText(tostring(self.stack))
		if db.stackPosition==2 or db.stackPosition==3 then
			self.stacktext:SetFont(fPB.stackFont, (self.stackSize or db.stackSize), "NORMAL")
			self.stackBg:SetWidth(self.stacktext:GetStringWidth())
			self.stackBg:SetHeight(self.stacktext:GetStringHeight())
			self.stackBg:Show()
		else
			self.stacktext:SetFont(fPB.stackFont, (self.stackSize or db.stackSize), "OUTLINE")
		end
		self.stacktext:Show()
	end
end

local function UpdateBuffIconOptions(self)
	self.texture:SetAllPoints(self)
	self.border:SetAllPoints(self)

	if db.borderStyle==1 then
		self.border:SetTexture("Interface\\Addons\\flyPlateBuffs\\texture\\border.tga")
		self.border:SetTexCoord(0.08,0.08, 0.08,0.92, 0.92,0.08, 0.92,0.92)
	elseif db.borderStyle==2 then
		self.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
		self.border:SetTexCoord(0.296875,0.5703125, 0,0.515625)
	end

	if db.showDuration then
		self.durationtext:ClearAllPoints()
		self.durationBg:ClearAllPoints()
		if db.durationPosition==1 then
			self.durationtext:SetPoint("TOP", self, "BOTTOM",0,-1)
			self.durationBg:SetPoint("CENTER", self.durationtext)
		elseif db.durationPosition==3 then
			self.durationtext:SetPoint("BOTTOM", self, "TOP",0,1)
			self.durationBg:SetPoint("CENTER", self.durationtext)
		else
			self.durationtext:SetPoint("CENTER", self, "CENTER",0,0)
		end
	end

	self.stacktext:ClearAllPoints()
	self.stackBg:ClearAllPoints()
	self.stacktext:SetTextColor(db.stackColor[1],db.stackColor[2],db.stackColor[3],1)
	if db.stackPosition==1 then
		self.stacktext:SetPoint("BOTTOMRIGHT", self,"BOTTOMRIGHT",-1,3)
	elseif db.stackPosition==2 then
		self.stacktext:SetPoint("TOP", self,"BOTTOM",0,-1)
		self.stackBg:SetPoint("CENTER", self.stacktext)
	else
		self.stacktext:SetPoint("BOTTOM", self,"TOP",0,1)
		self.stackBg:SetPoint("CENTER", self.stacktext)
	end
	self:EnableMouse(false)
end

--------------------------------------------------------------------------
-- CHANGED to pass the container we want (Buff or Debuff).
--------------------------------------------------------------------------
local function CreateBuffIcon(container, i)
	local auraIcon= CreateFrame("Button", nil, container)
	-- Note we pass "container" as parent, NOT "frame".
	auraIcon.texture= auraIcon:CreateTexture(nil, "BACKGROUND")
	auraIcon.border = auraIcon:CreateTexture(nil, "BORDER")
	
	auraIcon.cooldown= CreateFrame("Cooldown", nil, auraIcon, "CooldownFrameTemplate")
	auraIcon.cooldown:SetReverse(true)
	auraIcon.cooldown:SetDrawEdge(false)

	auraIcon.durationtext= auraIcon:CreateFontString(nil, "ARTWORK")
	auraIcon.durationBg   = auraIcon:CreateTexture(nil, "BORDER")
	auraIcon.durationBg:SetVertexColor(0,0,0,.75)

	auraIcon.stacktext= auraIcon:CreateFontString(nil, "ARTWORK")
	auraIcon.stackBg  = auraIcon:CreateTexture(nil, "BORDER")
	auraIcon.stackBg:SetVertexColor(0,0,0,.75)

	UpdateBuffIconOptions(auraIcon)

	auraIcon.stacktext:Hide()
	auraIcon.border:Hide()
	auraIcon.cooldown:Hide()
	auraIcon.durationtext:Hide()
	auraIcon.durationBg:Hide()
	auraIcon.stackBg:Hide()

	auraIcon:SetScript("OnHide", iconOnHide)
	auraIcon:SetScript("OnUpdate", iconOnUpdate)

	if MSQ then
		Group:AddButton(auraIcon, {
			Icon= auraIcon.texture,
			Cooldown= auraIcon.cooldown,
			Normal= auraIcon.border,
			Count= false,
			Duration= false,
			FloatingBG= false,
			Flash= false,
			Pushed= false,
			Disabled= false,
			Checked= false,
			Border= false,
			AutoCastable= false,
			Highlight= false,
			HotKey= false,
			Name= false,
			AutoCast= false,
		})
	end
	return auraIcon
end

--------------------------------------------------------------------------
-- NEW or CHANGED: We do everything in UpdateUnitAuras, but we create
-- separate frames for buffs vs. debuffs, fill them, then layout them.
--------------------------------------------------------------------------
local function UpdateUnitAuras(nameplateID, updateOptions)
	local frame= C_NamePlate_GetNamePlateForUnit(nameplateID)
	if not frame then return end

	if FilterUnits(nameplateID) then
		-- Hide both frames if present
		if frame.fPBiconsFrameBuffs   then frame.fPBiconsFrameBuffs:Hide() end
		if frame.fPBiconsFrameDebuffs then frame.fPBiconsFrameDebuffs:Hide() end
		return
	end

	ScanUnitBuffs(nameplateID, frame)
	if not PlatesBuffs[frame] then
		if frame.fPBiconsFrameBuffs   then frame.fPBiconsFrameBuffs:Hide() end
		if frame.fPBiconsFrameDebuffs then frame.fPBiconsFrameDebuffs:Hide() end
		return
	end

	-- sort if needed
	if not db.disableSort then
		table_sort(PlatesBuffs[frame].buffs, SortFunc)
		table_sort(PlatesBuffs[frame].debuffs, SortFunc)
	end

	-- If needed, create 2 frames:
	if not frame.fPBiconsFrameBuffs then
		local parent= db.parentWorldFrame and WorldFrame or frame
		frame.fPBiconsFrameBuffs= CreateFrame("Frame", nil, parent)
		frame.fPBiconsFrameBuffs.iconsFrame= {}
	end
	if not frame.fPBiconsFrameDebuffs then
		local parent= db.parentWorldFrame and WorldFrame or frame
		frame.fPBiconsFrameDebuffs= CreateFrame("Frame", nil, parent)
		frame.fPBiconsFrameDebuffs.iconsFrame= {}
	end

	local buffIcons= frame.fPBiconsFrameBuffs.iconsFrame
	local debuffIcons= frame.fPBiconsFrameDebuffs.iconsFrame

	frame.fPBiconsFrameBuffs:Hide()
	frame.fPBiconsFrameDebuffs:Hide()
	
	--------------------------------------------------------------------------
	-- 1) Buff icons
	--------------------------------------------------------------------------
	local buffs= PlatesBuffs[frame].buffs
	for i=1, #buffs do
		if not buffIcons[i] then
			buffIcons[i]= CreateBuffIcon(frame.fPBiconsFrameBuffs, i)
		end
		local aura= buffs[i]
		local icon= buffIcons[i]
		icon.type= aura.type
		icon.icon= aura.icon
		icon.stack= aura.stack
		icon.debufftype= aura.debufftype
		icon.duration= aura.duration
		icon.expiration= aura.expiration
		icon.id= aura.id
		icon.durationSize= aura.durationSize
		icon.stackSize= aura.stackSize
		icon.width= db.baseWidth* aura.scale
		icon.height= db.baseHeight* aura.scale

		if updateOptions then
			UpdateBuffIconOptions(icon)
		end
		UpdateBuffIcon(icon)
		icon:Show()
	end
	for i=#buffs+1, #buffIcons do
		buffIcons[i]:Hide()
	end

	-- layout buffs
	LayoutIcons(frame.fPBiconsFrameBuffs, buffIcons, true)
	frame.fPBiconsFrameBuffs:Show()

	-- anchor buff frame
	frame.fPBiconsFrameBuffs:ClearAllPoints()
	frame.fPBiconsFrameBuffs:SetPoint(
		db.buffAnchorPoint,
		frame,
		db.plateAnchorPointBuff,
		db.xOffsetBuff,
		db.yOffsetBuff
	)

	--------------------------------------------------------------------------
	-- 2) Debuff icons
	--------------------------------------------------------------------------
	local debuffs= PlatesBuffs[frame].debuffs
	for i=1, #debuffs do
		if not debuffIcons[i] then
			debuffIcons[i]= CreateBuffIcon(frame.fPBiconsFrameDebuffs, i)
		end
		local aura= debuffs[i]
		local icon= debuffIcons[i]
		icon.type= aura.type
		icon.icon= aura.icon
		icon.stack= aura.stack
		icon.debufftype= aura.debufftype
		icon.duration= aura.duration
		icon.expiration= aura.expiration
		icon.id= aura.id
		icon.durationSize= aura.durationSize
		icon.stackSize= aura.stackSize
		icon.width= db.baseWidth* aura.scale
		icon.height= db.baseHeight* aura.scale

		if updateOptions then
			UpdateBuffIconOptions(icon)
		end
		UpdateBuffIcon(icon)
		icon:Show()
	end
	for i=#debuffs+1, #debuffIcons do
		debuffIcons[i]:Hide()
	end

	-- layout debuffs
	LayoutIcons(frame.fPBiconsFrameDebuffs, debuffIcons, false)
	frame.fPBiconsFrameDebuffs:Show()

	-- anchor debuff frame
	frame.fPBiconsFrameDebuffs:ClearAllPoints()
	frame.fPBiconsFrameDebuffs:SetPoint(
		db.debuffAnchorPoint,
		frame,
		db.plateAnchorPointDebuff,
		db.xOffsetDebuff,
		db.yOffsetDebuff
	)

	-- if Masque is used
	if MSQ then
		Group:ReSkin()
	end
end

--------------------------------------------------------------------------
--  The rest: Nameplate_Added, Nameplate_Removed, etc.
--------------------------------------------------------------------------
local function Nameplate_Added(nameplateID)
	local frame= C_NamePlate_GetNamePlateForUnit(nameplateID)
	if frame then
		frame.namePlateUnitToken= nameplateID
		if frame.BuffFrame then
			if db.notHideOnPersonalResource and UnitIsUnit(nameplateID,"player") then
				frame.BuffFrame:SetAlpha(1)
			else
				frame.BuffFrame:SetAlpha(0)
			end
		end
		UpdateUnitAuras(nameplateID)
	end
end

local function Nameplate_Removed(nameplateID)
	local frame= C_NamePlate_GetNamePlateForUnit(nameplateID)
	if frame then
		if frame.fPBiconsFrameBuffs then
			frame.fPBiconsFrameBuffs:Hide()
		end
		if frame.fPBiconsFrameDebuffs then
			frame.fPBiconsFrameDebuffs:Hide()
		end
		if PlatesBuffs[frame] then
			PlatesBuffs[frame]= nil
		end
		
		local guid = UnitGUID(nameplateID)
        if guid then
            activeInterrupts[guid] = nil
        end
	end
end

--------------------------------------------------------------------------
--  Exported function to refresh all nameplates
--------------------------------------------------------------------------
function fPB.UpdateAllNameplates(updateOptions)
	for _, plate in ipairs(C_NamePlate_GetNamePlates()) do
		local unit= plate.namePlateUnitToken
		if unit then
			UpdateUnitAuras(unit, updateOptions)
		end
	end
end
local UpdateAllNameplates= fPB.UpdateAllNameplates

--------------------------------------------------------------------------
--  Spell table management
--------------------------------------------------------------------------
-- ( code as yours: AddNewSpell, RemoveSpell, ChangeSpellID, etc.)
local function FixSpells()
	for spell,s in pairs(db.Spells) do
		if not s.name then
			local name
			local sid= tonumber(spell) and tonumber(spell) or spell.spellID
			if sid then
				name= GetSpellInfo(sid)
			else
				name= tostring(spell)
			end
			db.Spells[spell].name= name
		end
	end
end

function fPB.CacheSpells()
	wipe(cachedSpells)
	for spell, s in pairs(db.Spells) do
		if not s.checkID and not db.ignoredDefaultSpells[spell] and s.name then
			if s.spellID then
				cachedSpells[s.name]= s.spellID
			else
				cachedSpells[s.name]= "noid"
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

--------------------------------------------------------------------------
--  DB init
--------------------------------------------------------------------------
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
	db= fPB.db.profile
	fPB.OptionsOnEnable()
	UpdateAllNameplates(true)
end

local function Initialize()
	if flyPlateBuffsDB and (not flyPlateBuffsDB.version or flyPlateBuffsDB.version<2) then
		ConvertDBto2()
	end
	fPB.db= LibStub("AceDB-3.0"):New("flyPlateBuffsDB", DefaultSettings, true)
	fPB.db.RegisterCallback(fPB,"OnProfileChanged","OnProfileChanged")
	fPB.db.RegisterCallback(fPB,"OnProfileCopied","OnProfileChanged")
	fPB.db.RegisterCallback(fPB,"OnProfileReset","OnProfileChanged")

	db= fPB.db.profile
	fPB.font= fPB.LSM:Fetch("font", db.font)
	fPB.stackFont= fPB.LSM:Fetch("font", db.stackFont)
	FixSpells()
	fPB.CacheSpells()

	config:RegisterOptionsTable(AddonName, fPB.MainOptionTable)
	fPBMainOptions= dialog:AddToBlizOptions(AddonName, AddonName)

	config:RegisterOptionsTable(AddonName.." Spells", fPB.SpellsTable)
	fPBSpellsList= dialog:AddToBlizOptions(AddonName.." Spells", L["Specific spells"], AddonName)

	config:RegisterOptionsTable(AddonName.." Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(fPB.db))
	fPBProfilesOptions= dialog:AddToBlizOptions(AddonName.." Profiles", L["Profiles"], AddonName)

	SLASH_FLYPLATEBUFFS1, SLASH_FLYPLATEBUFFS2= "/fpb","/pb"
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

fPB.Events= CreateFrame("Frame")
fPB.Events:RegisterEvent("ADDON_LOADED")
fPB.Events:RegisterEvent("PLAYER_LOGIN")
fPB.Events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
fPB.Events:SetScript("OnEvent", function(self, event, ...)
	if event=="ADDON_LOADED" and (...)==AddonName then
		Initialize()
	elseif event=="PLAYER_LOGIN" then
		fPB.OptionsOnEnable()
		if db.showSpellID then
			fPB.ShowSpellID()
		end
		MSQ= LibStub("Masque",true)
		if MSQ then
			Group= MSQ:Group(AddonName)
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
	elseif event=="PLAYER_REGEN_DISABLED" then
		fPB.Events:RegisterEvent("UNIT_AURA")
		UpdateAllNameplates()
	elseif event=="PLAYER_REGEN_ENABLED" then
		fPB.Events:UnregisterEvent("UNIT_AURA")
		UpdateAllNameplates()
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, event, _, _, _, _, _, destGUID, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo(...)


        if event == "SPELL_INTERRUPT" then
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
        end
	elseif event=="NAME_PLATE_UNIT_ADDED" then
		Nameplate_Added(...)
	elseif event=="NAME_PLATE_UNIT_REMOVED" then
		Nameplate_Removed(...)
	elseif event=="UNIT_AURA" then
		local unit= ...
		if unit and strmatch(unit,"nameplate%d+") then
			UpdateUnitAuras(unit)
		end
	end
end)
