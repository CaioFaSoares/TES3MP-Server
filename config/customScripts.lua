-- Load up your custom scripts here! Ideally, your custom scripts will be placed in the scripts/custom folder and then get loaded like this:
--
-- require("custom/yourScript")
--
-- Refer to the Tutorial.md file for information on how to use various event and command hooks in your scripts.

require("custom/constantEffectSummonFix")
require("custom/customMerchantRestock")
require("custom/dbFix")
require("custom/periodicCellResets")
require("custom/preventPrisonSkilldowns")
require("custom/respawnAtCellEntry")

altStart = require("custom/altStart")
coopInstruments = require("custom/coopInstruments")
enchantTweaks = require("custom/enchantTweaks")
familiars = require("custom/familiars")
fixedLevelupAttributes = require("custom/fixedLevelupAttributes")
guarBanker = require("custom/guarBanker")
playerPacketHelper = require("custom/playerPacketHelper")
noteWriting = require("custom/noteWriting")
playerCorpsesPersist = require("custom/playerCorpsesPersist")
starterEquipment = require("custom/starterEquipment")
allyQuestShare = require("custom/allyQuestShare")

