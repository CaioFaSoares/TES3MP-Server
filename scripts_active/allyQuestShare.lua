--[[
    Ally Quest & Topic Sharing Plugin
    version 1.0 (for TES3MP 0.8.0+)
    
    This plugin enables characters who are allies (invite-accepted via `/invite` and `/join`)
    to share ONLY their journal (quests) and dialogue topics.
--]]

local allyQuestShare = {}

-- Helper to check if a journal list contains a quest entry/index
local function hasJournalEntry(journal, quest, index)
    for _, item in ipairs(journal) do
        if item.quest == quest and item.index == index then
            return true
        end
    end
    return false
end

-- Helper to check if a topics list contains a topicId
local function hasTopic(topics, topicId)
    for _, id in ipairs(topics) do
        if id == topicId then
            return true
        end
    end
    return false
end

-- Bidirectional merge of journal and topics between playerA and playerB
local function mergeAlliesData(playerA, playerB)
    local journalModifiedA = false
    local journalModifiedB = false

    if playerA.data.journal == nil then playerA.data.journal = {} end
    if playerB.data.journal == nil then playerB.data.journal = {} end

    -- Merge A's journal to B
    for _, journalItem in ipairs(playerA.data.journal) do
        if not hasJournalEntry(playerB.data.journal, journalItem.quest, journalItem.index) then
            table.insert(playerB.data.journal, journalItem)
            journalModifiedB = true
        end
    end

    -- Merge B's journal to A
    for _, journalItem in ipairs(playerB.data.journal) do
        if not hasJournalEntry(playerA.data.journal, journalItem.quest, journalItem.index) then
            table.insert(playerA.data.journal, journalItem)
            journalModifiedA = true
        end
    end

    local topicsModifiedA = false
    local topicsModifiedB = false

    if playerA.data.topics == nil then playerA.data.topics = {} end
    if playerB.data.topics == nil then playerB.data.topics = {} end

    -- Merge A's topics to B
    for _, topicId in ipairs(playerA.data.topics) do
        if not hasTopic(playerB.data.topics, topicId) then
            table.insert(playerB.data.topics, topicId)
            topicsModifiedB = true
        end
    end

    -- Merge B's topics to A
    for _, topicId in ipairs(playerB.data.topics) do
        if not hasTopic(playerA.data.topics, topicId) then
            table.insert(playerA.data.topics, topicId)
            topicsModifiedA = true
        end
    end

    -- Save and load updates for Player A if modified
    if journalModifiedA or topicsModifiedA then
        if playerA:IsLoggedIn() then
            if journalModifiedA then
                playerA:LoadJournal()
            end
            if topicsModifiedA then
                playerA:LoadTopics()
            end
            playerA:QuicksaveToDrive()
        else
            playerA:SaveToDrive()
        end
    end

    -- Save and load updates for Player B if modified
    if journalModifiedB or topicsModifiedB then
        if playerB:IsLoggedIn() then
            if journalModifiedB then
                playerB:LoadJournal()
            end
            if topicsModifiedB then
                playerB:LoadTopics()
            end
            playerB:QuicksaveToDrive()
        else
            playerB:SaveToDrive()
        end
    end
end

-- Hook into OnPlayerFinishLogin to merge data with allies on login
customEventHooks.registerHandler("OnPlayerFinishLogin", function(eventStatus, pid)
    local player = Players[pid]
    if player == nil or not player:IsLoggedIn() then return end

    if player.data.alliedPlayers == nil then player.data.alliedPlayers = {} end

    for _, allyName in ipairs(player.data.alliedPlayers) do
        local allyPlayer = logicHandler.GetPlayerByName(allyName)
        if allyPlayer ~= nil then
            mergeAlliesData(player, allyPlayer)
        end
    end
end)

-- Hook into OnPlayerJournal to share journal progress in real-time
customEventHooks.registerHandler("OnPlayerJournal", function(eventStatus, pid, playerPacket)
    local player = Players[pid]
    if player == nil or not player:IsLoggedIn() then return end

    if player.data.alliedPlayers == nil then player.data.alliedPlayers = {} end

    for _, allyName in ipairs(player.data.alliedPlayers) do
        local allyPlayer = logicHandler.GetPlayerByName(allyName)
        if allyPlayer ~= nil then
            local modified = false
            local packetModified = false

            if allyPlayer:IsLoggedIn() then
                tes3mp.ClearJournalChanges(allyPlayer.pid)
            end

            for _, journalItem in ipairs(playerPacket.journal) do
                if allyPlayer.data.journal == nil then allyPlayer.data.journal = {} end

                if not hasJournalEntry(allyPlayer.data.journal, journalItem.quest, journalItem.index) then
                    table.insert(allyPlayer.data.journal, journalItem)
                    modified = true

                    if allyPlayer:IsLoggedIn() then
                        packetModified = true
                        if journalItem.type == enumerations.journal.ENTRY then
                            local actorRefId = journalItem.actorRefId or "player"
                            if journalItem.timestamp ~= nil then
                                tes3mp.AddJournalEntryWithTimestamp(allyPlayer.pid, journalItem.quest, journalItem.index, actorRefId,
                                    journalItem.timestamp.daysPassed, journalItem.timestamp.month, journalItem.timestamp.day)
                            else
                                tes3mp.AddJournalEntry(allyPlayer.pid, journalItem.quest, journalItem.index, actorRefId)
                            end
                        else
                            tes3mp.AddJournalIndex(allyPlayer.pid, journalItem.quest, journalItem.index)
                        end
                    end
                end
            end

            if modified then
                if allyPlayer:IsLoggedIn() then
                    if packetModified then
                        tes3mp.SendJournalChanges(allyPlayer.pid)
                    end
                    allyPlayer:QuicksaveToDrive()
                else
                    allyPlayer:SaveToDrive()
                end
            end
        end
    end
end)

-- Hook into OnPlayerTopic to share topic progress in real-time
customEventHooks.registerHandler("OnPlayerTopic", function(eventStatus, pid)
    local player = Players[pid]
    if player == nil or not player:IsLoggedIn() then return end

    if player.data.alliedPlayers == nil then player.data.alliedPlayers = {} end

    local topicChangesSize = tes3mp.GetTopicChangesSize(pid)
    if topicChangesSize == 0 then return end

    local newTopics = {}
    for i = 0, topicChangesSize - 1 do
        table.insert(newTopics, tes3mp.GetTopicId(pid, i))
    end

    for _, allyName in ipairs(player.data.alliedPlayers) do
        local allyPlayer = logicHandler.GetPlayerByName(allyName)
        if allyPlayer ~= nil then
            local modified = false
            local packetModified = false

            if allyPlayer:IsLoggedIn() then
                tes3mp.ClearTopicChanges(allyPlayer.pid)
            end

            for _, topicId in ipairs(newTopics) do
                if allyPlayer.data.topics == nil then allyPlayer.data.topics = {} end

                if not hasTopic(allyPlayer.data.topics, topicId) then
                    table.insert(allyPlayer.data.topics, topicId)
                    modified = true

                    if allyPlayer:IsLoggedIn() then
                        packetModified = true
                        tes3mp.AddTopic(allyPlayer.pid, topicId)
                    end
                end
            end

            if modified then
                if allyPlayer:IsLoggedIn() then
                    if packetModified then
                        tes3mp.SendTopicChanges(allyPlayer.pid)
                    end
                    allyPlayer:QuicksaveToDrive()
                else
                    allyPlayer:SaveToDrive()
                end
            end
        end
    end
end)

-- Wrap /join command to merge progress immediately upon alliance confirmation
customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
    -- Warning if server-wide sharing is active in config.lua
    if config.shareJournal == true then
        tes3mp.LogMessage(enumerations.log.WARN, "[allyQuestShare] Warning: config.shareJournal is enabled in config.lua. Per-ally quest sharing might be redundant.")
    end
    if config.shareTopics == true then
        tes3mp.LogMessage(enumerations.log.WARN, "[allyQuestShare] Warning: config.shareTopics is enabled in config.lua. Per-ally topic sharing might be redundant.")
    end

    local originalJoinCallback = customCommandHooks.getCallback("join")
    if originalJoinCallback ~= nil then
        customCommandHooks.registerCommand("join", function(pid, cmd)
            -- Call default join logic
            originalJoinCallback(pid, cmd)

            -- Perform the initial bidirection merge
            if pid == tonumber(cmd[2]) then return end
            if logicHandler.CheckPlayerValidity(pid, cmd[2]) then
                local targetPid = tonumber(cmd[2])
                local player = Players[pid]
                local targetPlayer = Players[targetPid]
                if player ~= nil and targetPlayer ~= nil then
                    if tableHelper.containsValue(player.data.alliedPlayers, targetPlayer.accountName) then
                        mergeAlliesData(player, targetPlayer)
                    end
                end
            end
        end)
    else
        tes3mp.LogMessage(enumerations.log.ERROR, "[allyQuestShare] Failed to wrap '/join' command callback. Command callback not found.")
    end
end)

return allyQuestShare
