-- Timers from logs/2026-04-16-18.04.22 WoWCombatLog.txt (Basalthane, NPC 10185).
local mod	= DBM:NewMod("Basalthane", "DBM-Onyxia", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2 $"):sub(12, -3))
mod:SetCreatureID(10185)
mod:SetUsedIcons(8)
mod:RegisterCombat("combat")

mod:AddButton("TimerTestButton", function() mod:TimerTestPreview() end, "misc")
mod:AddBoolOption("SetIconOnMagmaPool", true)

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED"
)

-- Boss abilities
local annihilationStrike	= 2108206
local infernoTrail			= 2108217
local eruption				= 2108227
local fierceBlow			= 975011
-- Next spell id in the Basalthane 21082xxx block (verify in-game if the timer never updates)
local heatSplash			= 2108212
local flashBurnDebuff		= 2108201
-- Ground effect from Eruption (combat log name); APPLIED on players standing in pool
local magmaPool				= 2108233
-- Self-DEBUFF on Basalthane when a Volatile Pillar dies; next boss cast ~20s later in log
local pillarStunDebuff		= 2108234
local pillarStunDuration	= 20

-- Cast times (seconds from SPELL_CAST_START to impact / next event in log)
local castAnnihilation		= 3
local castInferno			= 3
local castEruption			= 5
-- Cooldowns (seconds between matching events in log)
local cdInfernoRepeat		= 14			-- Inferno Trail start -> next Inferno start
local cdAnnihilationRepeat	= 18			-- rough anni start -> next anni start (varies with movement)
local cdFierceBlow			= 7.5
local firstFierceBlow		= 10.3
local firstAnnihilation		= 3
-- First Inferno Trail cast starts ~3s after first Annihilation cast start (log: anni -> inferno ≈ 3s)
local firstInferno			= firstAnnihilation + 3
local firstEruption			= 48			-- pull -> first Eruption cast (~45s after first Annihilation start in log)
local cdEruptionRepeat		= 56
-- Heat Splash: not in sample log; tune from live pulls
local firstHeatSplash		= 11
local cdHeatSplashRepeat	= 12
-- After Eruption cast begins, next Annihilation / Inferno in log (~11s / ~14s from cast start)
local delayAnniAfterEruption	= 11
local delayInfernoAfterEruption = 14

-- DBM boss panel "Test pull timers": preview length (seconds), then bars are cleared if still not in combat
local timerTestPreviewSeconds	= 12

local warnAnnihilation		= mod:NewSpellAnnounce(annihilationStrike, 3)
local warnInferno			= mod:NewSpellAnnounce(infernoTrail, 3)
local warnEruption			= mod:NewSpellAnnounce(eruption, 3)
local warnFierceBlow		= mod:NewTargetAnnounce(fierceBlow, 2)
local warnHeatSplash		= mod:NewSpellAnnounce(heatSplash, 3, nil, true, "WarnHeatSplash")
local specWarnFlashBurn		= mod:NewSpecialWarningYou(flashBurnDebuff, true)
local specWarnMagmaPool		= mod:NewSpecialWarningYou(magmaPool, true)

local timerAnnihilationCast	= mod:NewCastTimer(castAnnihilation, annihilationStrike)
local timerInfernoCast		= mod:NewCastTimer(castInferno, infernoTrail)
local timerEruptionCast		= mod:NewCastTimer(castEruption, eruption)

-- Same spell ID: distinct option keys + localization (see localization.en.lua).
-- Pass nil for timerText (not `true`): without DBM's arg-shuffle, `true` is mis-read as optionDefault and breaks Options (must stay boolean for the GUI).
local timerFirstAnnihilation	= mod:NewNextTimer(firstAnnihilation, annihilationStrike, nil, true, "TimerFirstAnnihilationStrike")
local timerNextAnnihilation	= mod:NewNextTimer(cdAnnihilationRepeat, annihilationStrike, nil, true, "TimerNextAnnihilationStrike")
local timerNextInferno		= mod:NewNextTimer(cdInfernoRepeat, infernoTrail)
local timerNextFierceBlow	= mod:NewNextTimer(cdFierceBlow, fierceBlow)
local timerNextHeatSplash	= mod:NewNextTimer(cdHeatSplashRepeat, heatSplash, "TimerNextHeatSplashBar", true, "TimerNextHeatSplash")
local timerNextEruption		= mod:NewNextTimer(cdEruptionRepeat, eruption)
local timerPillarStun		= mod:NewBuffActiveTimer(pillarStunDuration, pillarStunDebuff, "TimerPillarStun", true)

local firstAnnihilationPhase	= true

-- New timer option keys must exist as booleans or DBM will not draw the bar (nil = off).
function mod:OnInitialize()
	if self.Options.TimerNextHeatSplash == nil then
		self.Options.TimerNextHeatSplash = true
	end
	if self.Options.WarnHeatSplash == nil then
		self.Options.WarnHeatSplash = true
	end
end

local function isBossSource(args)
	return mod:GetCIDFromGUID(args.sourceGUID) == 10185
end

local function isBossDest(args)
	return mod:GetCIDFromGUID(args.destGUID) == 10185
end

function mod:OnCombatStart(delay)
	if self.inCombat then
		self:UnscheduleMethod("TimerTestPreviewEnd")
		self._timerTestPreview = nil
	end
	firstAnnihilationPhase = true
	timerFirstAnnihilation:Start(firstAnnihilation - delay)
	timerNextInferno:Start(firstInferno - delay)
	timerNextFierceBlow:Start(firstFierceBlow - delay)
	timerNextHeatSplash:Start(firstHeatSplash - delay)
	timerNextEruption:Start(firstEruption - delay)
end

function mod:SPELL_CAST_START(args)
	if not isBossSource(args) then return end
	if args:IsSpellID(annihilationStrike) then
		warnAnnihilation:Show()
		timerAnnihilationCast:Start(castAnnihilation)
		timerNextAnnihilation:Start(cdAnnihilationRepeat)
		if firstAnnihilationPhase then
			timerNextInferno:Start(3)
			firstAnnihilationPhase = false
		else
			timerNextInferno:Start(11)
		end
	elseif args:IsSpellID(infernoTrail) then
		warnInferno:Show()
		timerInfernoCast:Start(castInferno)
		timerNextInferno:Start(cdInfernoRepeat)
	elseif args:IsSpellID(eruption) then
		warnEruption:Show()
		timerEruptionCast:Start(castEruption)
		timerNextEruption:Start(cdEruptionRepeat)
		timerNextAnnihilation:Start(delayAnniAfterEruption)
		timerNextInferno:Start(delayInfernoAfterEruption)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if not isBossSource(args) then return end
	if args:IsSpellID(fierceBlow) then
		warnFierceBlow:Show(args.destName)
		timerNextFierceBlow:Start()
	elseif args:IsSpellID(heatSplash) then
		warnHeatSplash:Show()
		timerNextHeatSplash:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not isBossSource(args) then return end
	if args:IsSpellID(flashBurnDebuff) and args:IsDestTypePlayer() then
		if args:IsPlayer() then
			specWarnFlashBurn:Show()
		end
	elseif args:IsSpellID(magmaPool) and args:IsDestTypePlayer() then
		if self.Options.SetIconOnMagmaPool then
			self:SetIcon(args.destName, 8)
		end
		if args:IsPlayer() then
			specWarnMagmaPool:Show()
			SendChatMessage(L.YellEruption:format(UnitName("player")), "YELL")
		end
	elseif args:IsSpellID(pillarStunDebuff) and isBossSource(args) and isBossDest(args) and args.destGUID == args.sourceGUID then
		timerPillarStun:Start()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(magmaPool) and args:IsDestTypePlayer() and self.Options.SetIconOnMagmaPool then
		self:RemoveIcon(args.destName)
	elseif args:IsSpellID(pillarStunDebuff) and isBossDest(args) then
		timerPillarStun:Cancel()
	end
end

function mod:TimerTestPreview()
	if self.inCombat then
		DBM:AddMsg(L.TimerTestInCombat)
		return
	end
	self:UnscheduleMethod("TimerTestPreviewEnd")
	self:Stop()
	self._timerTestPreview = true
	self:OnCombatStart(0)
	self:ScheduleMethod(timerTestPreviewSeconds, "TimerTestPreviewEnd")
	DBM:AddMsg(L.TimerTestStarted:format(timerTestPreviewSeconds))
end

function mod:TimerTestPreviewEnd()
	local wasPreview = self._timerTestPreview
	self._timerTestPreview = nil
	if wasPreview and not self.inCombat then
		self:Stop()
	end
end
