-- Timers and spell IDs from combat log (Basalthane, NPC id 10185).
local mod	= DBM:NewMod("Basalthane", "DBM-Onyxia", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 1 $"):sub(12, -3))
mod:SetCreatureID(10185)
mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED"
)

local annihilationStrike	= 2108206
local infernoTrail			= 2108217
local eruption				= 2108227
local fierceBlow			= 975011
local flashBurnDebuff		= 2108201

local warnAnnihilation		= mod:NewSpellAnnounce(annihilationStrike, 3)
local warnInferno			= mod:NewSpellAnnounce(infernoTrail, 3)
local warnEruption			= mod:NewSpellAnnounce(eruption, 3)
local warnFierceBlow		= mod:NewTargetAnnounce(fierceBlow, 2)
local specWarnFlashBurn		= mod:NewSpecialWarningYou(flashBurnDebuff, true)

local timerAnnihilationCast	= mod:NewCastTimer(3, annihilationStrike)
local timerInfernoCast		= mod:NewCastTimer(3, infernoTrail)
local timerEruptionCast		= mod:NewCastTimer(8, eruption)

local timerFirstAnnihilation	= mod:NewNextTimer(3, annihilationStrike)
local timerNextFierceBlow	= mod:NewNextTimer(7.5, fierceBlow)
local timerNextEruption		= mod:NewNextTimer(56, eruption)

local function isBossSource(args)
	return mod:GetCIDFromGUID(args.sourceGUID) == 10185
end

function mod:OnCombatStart(delay)
	timerFirstAnnihilation:Start(3 - delay)
	timerNextFierceBlow:Start(10.3 - delay)
	timerNextEruption:Start(48 - delay)
end

function mod:SPELL_CAST_START(args)
	if not isBossSource(args) then return end
	if args:IsSpellID(annihilationStrike) then
		warnAnnihilation:Show()
		timerAnnihilationCast:Start()
	elseif args:IsSpellID(infernoTrail) then
		warnInferno:Show()
		timerInfernoCast:Start()
	elseif args:IsSpellID(eruption) then
		warnEruption:Show()
		timerEruptionCast:Start()
		timerNextEruption:Start()
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
	if args:IsSpellID(flashBurnDebuff) and args:IsDestTypePlayer() then
		if args:IsPlayer() then
			specWarnFlashBurn:Show()
		end
	end
end
