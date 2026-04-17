-- Timers from logs/2026-04-16-18.04.22 WoWCombatLog.txt (Basalthane, NPC 10185).
local mod	= DBM:NewMod("Basalthane", "DBM-Onyxia", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2 $"):sub(12, -3))
mod:SetCreatureID(10185)
mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED"
)

-- Boss abilities
local annihilationStrike	= 2108206
local infernoTrail			= 2108217
local eruption				= 2108227
local fierceBlow			= 975011
local flashBurnDebuff		= 2108201
-- Ground effect from Eruption (combat log name); APPLIED on players standing in pool
local magmaPool				= 2108233

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
local firstEruption			= 48			-- pull -> first Eruption cast (~45s after first Annihilation start in log)
local cdEruptionRepeat		= 56
-- After Eruption cast begins, next Annihilation / Inferno in log (~11s / ~14s from cast start)
local delayAnniAfterEruption	= 11
local delayInfernoAfterEruption = 14

local warnAnnihilation		= mod:NewSpellAnnounce(annihilationStrike, 3)
local warnInferno			= mod:NewSpellAnnounce(infernoTrail, 3)
local warnEruption			= mod:NewSpellAnnounce(eruption, 3)
local warnFierceBlow		= mod:NewTargetAnnounce(fierceBlow, 2)
local specWarnFlashBurn		= mod:NewSpecialWarningYou(flashBurnDebuff, true)
local specWarnMagmaPool		= mod:NewSpecialWarningYou(magmaPool, true)

local timerAnnihilationCast	= mod:NewCastTimer(castAnnihilation, annihilationStrike)
local timerInfernoCast		= mod:NewCastTimer(castInferno, infernoTrail)
local timerEruptionCast		= mod:NewCastTimer(castEruption, eruption)

local timerFirstAnnihilation	= mod:NewNextTimer(firstAnnihilation, annihilationStrike)
local timerNextAnnihilation	= mod:NewNextTimer(cdAnnihilationRepeat, annihilationStrike)
local timerNextInferno		= mod:NewNextTimer(cdInfernoRepeat, infernoTrail)
local timerNextFierceBlow	= mod:NewNextTimer(cdFierceBlow, fierceBlow)
local timerNextEruption		= mod:NewNextTimer(cdEruptionRepeat, eruption)

local firstAnnihilationPhase	= true

local function isBossSource(args)
	return mod:GetCIDFromGUID(args.sourceGUID) == 10185
end

function mod:OnCombatStart(delay)
	firstAnnihilationPhase = true
	timerFirstAnnihilation:Start(firstAnnihilation - delay)
	timerNextFierceBlow:Start(firstFierceBlow - delay)
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
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if not isBossSource(args) then return end
	if args:IsSpellID(flashBurnDebuff) and args:IsDestTypePlayer() then
		if args:IsPlayer() then
			specWarnFlashBurn:Show()
		end
	elseif args:IsSpellID(magmaPool) and args:IsDestTypePlayer() then
		if args:IsPlayer() then
			specWarnMagmaPool:Show()
			SendChatMessage(L.YellEruption, "YELL")
		end
	end
end
