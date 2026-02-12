-- EasyChatTWW Copy Addon for WoW
-- Simple Version - All Chat Messages in One Window

local addonName = "EasyChatTWW"
local ECC = {}

-- Variables
local chatHistory = {}
local maxHistoryLines = 500
local copyFrame
local chatCopyButton

-- Initialize addon
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

-- All chat message types
local chatEvents = {
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_SYSTEM",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_ACHIEVEMENT",
    "CHAT_MSG_COMBAT_XP_GAIN",
    "CHAT_MSG_COMBAT_HONOR_GAIN",
    "CHAT_MSG_LOOT",
    "CHAT_MSG_COMBAT_FACTION_CHANGE",
    "CHAT_MSG_COMBAT_MISC_INFO"
}

for _, event in ipairs(chatEvents) do
    frame:RegisterEvent(event)
end

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        print("|cff00ff00EasyChatTWW|r loaded! Use /ecc for chat copy")
        ECC:CreateCopyFrame()
    elseif event == "PLAYER_LOGIN" then
        C_Timer.After(2, function()
            ECC:SetupChatHooks()
            ECC:CreateChatCopyButton()
        end)
    elseif string.find(event, "CHAT_MSG_") then
        ECC:StoreChatMessage(event, ...)
    end
end)

-- Create Copy Button in Chat
function ECC:CreateChatCopyButton()
    if chatCopyButton then return end
    
    -- Create button next to chat frame
    chatCopyButton = CreateFrame("Button", "EasyChatTWWCopyButton", ChatFrame1, "UIPanelButtonTemplate")
    chatCopyButton:SetSize(80, 20)
    chatCopyButton:SetPoint("TOPRIGHT", ChatFrame1, "TOPRIGHT", 0, 20)
    chatCopyButton:SetText("Copy Chat")
    chatCopyButton:SetScript("OnClick", function()
        ECC:ShowCopyFrame()
    end)
    
    -- Add tooltip
    chatCopyButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("EasyChatTWW - Opens chat copy window", 1, 1, 1)
        GameTooltip:Show()
    end)
    chatCopyButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    print("|cff00ff00EasyChatTWW:|r Copy button added to chat!")
end

-- Simple Chat Setup
function ECC:SetupChatHooks()
    -- Hook only main chat window (ChatFrame1)
    local chatFrame = ChatFrame1
    if chatFrame then
        local originalAddMessage = chatFrame.AddMessage
        chatFrame.AddMessage = function(self, text, r, g, b, ...)
            -- Forward original message
            originalAddMessage(self, text, r, g, b, ...)
            
            -- Store all messages
            if text and type(text) == "string" and text ~= "" then
                local timestamp = date("%H:%M:%S")
                local formattedMessage = string.format("[%s] %s", timestamp, text)
                
                table.insert(chatHistory, formattedMessage)
                
                -- Limit history
                if #chatHistory > maxHistoryLines then
                    table.remove(chatHistory, 1)
                end
                
                -- Auto-Update
                if copyFrame and copyFrame:IsShown() and copyFrame.autoUpdate then
                    ECC:UpdateCopyFrameText()
                end
            end
        end
        print("|cff00ff00EasyChatTWW:|r Chat hook activated!")
    end
end

-- Store chat messages (SIMPLE)
function ECC:StoreChatMessage(event, message, sender, ...)
    local timestamp = date("%H:%M:%S")
    local channelType = string.gsub(event, "CHAT_MSG_", "")
    local playerName = sender or "System"
    
    local formattedMessage = string.format("[%s] [%s] %s: %s", 
        timestamp, 
        channelType, 
        playerName, 
        message or ""
    )
    
    table.insert(chatHistory, formattedMessage)
    
    -- Limit history
    if #chatHistory > maxHistoryLines then
        table.remove(chatHistory, 1)
    end
    
    -- Auto-Update
    if copyFrame and copyFrame:IsShown() and copyFrame.autoUpdate then
        ECC:UpdateCopyFrameText()
    end
end

-- Update text in copy window (SIMPLE)
function ECC:UpdateCopyFrameText()
    if not copyFrame or not copyFrame.editBox then return end
    
    local chatText = table.concat(chatHistory, "\n")
    
    local cursorPosition = copyFrame.editBox:GetCursorPosition()
    local scrollPosition = copyFrame.scrollFrame:GetVerticalScroll()
    
    copyFrame.editBox:SetText(chatText)
    
    -- Keep scroll position
    local scrollRange = copyFrame.scrollFrame:GetVerticalScrollRange()
    if scrollRange and scrollRange > 0 then
        if scrollPosition >= scrollRange then
            copyFrame.scrollFrame:SetVerticalScroll(scrollRange)
        else
            copyFrame.scrollFrame:SetVerticalScroll(scrollPosition)
        end
    end
    
    copyFrame.editBox:SetCursorPosition(cursorPosition)
end

-- FIXED: Automatic copying to clipboard
function ECC:CopyToClipboard(text)
    if not text or text == "" then
        print("|cffff0000EasyChatTWW:|r No text to copy!")
        return false
    end
    
    -- Use the existing editBox for copying
    if copyFrame and copyFrame.editBox then
        copyFrame.editBox:SetText(text)
        copyFrame.editBox:SetFocus()
        copyFrame.editBox:HighlightText()  -- Select all text - SIMPLIFIED
        
        -- Give user instruction
        print("|cff00ff00EasyChatTWW:|r Text selected! Press CTRL+C to copy " .. string.len(text) .. " characters")
        
        return true
    else
        print("|cffff0000EasyChatTWW:|r Copy window not available!")
        return false
    end
end

-- Create copy frame (SIMPLE)
function ECC:CreateCopyFrame()
    -- Create main frame
    copyFrame = CreateFrame("Frame", "EasyChatTWWCopyFrame", UIParent, "BackdropTemplate")
    copyFrame:SetSize(650, 550)
    copyFrame:SetPoint("CENTER")
    copyFrame:Hide()
    copyFrame:SetMovable(true)
    copyFrame:EnableMouse(true)
    copyFrame:RegisterForDrag("LeftButton")
    copyFrame:SetScript("OnDragStart", copyFrame.StartMoving)
    copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing)
    
    -- Auto-Update enabled
    copyFrame.autoUpdate = true
    
    -- Black background with border
    copyFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    copyFrame:SetBackdropColor(0, 0, 0, 0.9)
    copyFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    
    -- Title
    copyFrame.title = copyFrame:CreateFontString(nil, "OVERLAY")
    copyFrame.title:SetFontObject("GameFontNormalLarge")
    copyFrame.title:SetPoint("TOP", copyFrame, "TOP", 0, -10)
    copyFrame.title:SetText("EasyChatTWW - All Chat Messages")
    
    -- Create content area
    local contentFrame = CreateFrame("Frame", nil, copyFrame)
    contentFrame:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 12, -40)
    contentFrame:SetPoint("BOTTOMRIGHT", copyFrame, "BOTTOMRIGHT", -12, 80)
    copyFrame.contentFrame = contentFrame
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "EasyChatTWWScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", contentFrame, "BOTTOMRIGHT", -24, 0)
    copyFrame.scrollFrame = scrollFrame
    
    -- Edit box
    local editBox = CreateFrame("EditBox", "EasyChatTWWEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetHeight(5000)
    editBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
    editBox:EnableMouse(true)
    editBox:SetMaxLetters(0)  -- No limit
    
    scrollFrame:SetScrollChild(editBox)
    copyFrame.editBox = editBox
    
    -- Auto-scroll to bottom when opening
    copyFrame:SetScript("OnShow", function()
        C_Timer.After(0.1, function()
            local scrollRange = scrollFrame:GetVerticalScrollRange()
            if scrollRange and scrollRange > 0 then
                scrollFrame:SetVerticalScroll(scrollRange)
            end
        end)
    end)
    
    -- Create control buttons
    ECC:CreateControlButtons()
end

-- Create Control Buttons for Copy Frame (SIMPLE)
function ECC:CreateControlButtons()
    if not copyFrame then return end
    
    -- Button container
    local buttonY = 45
    
    -- Mark All button - SIMPLIFIED
    local copyButton = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
    copyButton:SetPoint("BOTTOMLEFT", copyFrame, "BOTTOMLEFT", 15, buttonY)
    copyButton:SetSize(100, 25)
    copyButton:SetText("Focus Text")
    copyButton:SetScript("OnClick", function()
        if copyFrame.editBox then
            copyFrame.editBox:SetFocus()
        end
    end)
    
    -- Clear button
    local clearButton = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
    clearButton:SetPoint("LEFT", copyButton, "RIGHT", 10, 0)
    clearButton:SetSize(100, 25)
    clearButton:SetText("Clear")
    clearButton:SetScript("OnClick", function()
        copyFrame.editBox:SetText("")
        chatHistory = {}
        print("|cff00ff00EasyChatTWW:|r Chat history cleared!")
    end)
    
    -- Refresh button
    local refreshButton = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
    refreshButton:SetPoint("LEFT", clearButton, "RIGHT", 10, 0)
    refreshButton:SetSize(100, 25)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        ECC:UpdateCopyFrameText()
        print("|cff00ff00EasyChatTWW:|r Chat refreshed!")
    end)
    
    -- Auto-Update Toggle (ENABLED)
    local autoUpdateButton = CreateFrame("CheckButton", nil, copyFrame, "ChatConfigCheckButtonTemplate")
    autoUpdateButton:SetPoint("BOTTOMLEFT", copyFrame, "BOTTOMLEFT", 15, 15)
    autoUpdateButton:SetSize(24, 24)
    autoUpdateButton:SetChecked(true) -- ENABLED!
    autoUpdateButton:SetScript("OnClick", function()
        copyFrame.autoUpdate = not copyFrame.autoUpdate
        print("|cff00ff00EasyChatTWW:|r Auto-Update " .. (copyFrame.autoUpdate and "enabled" or "disabled"))
    end)
    
    -- Auto-Update Label
    local autoUpdateText = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoUpdateText:SetPoint("LEFT", autoUpdateButton, "RIGHT", 5, 0)
    autoUpdateText:SetText("Auto-Update")
    
    -- Copy instruction hint
    local copyHintText = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    copyHintText:SetPoint("LEFT", autoUpdateText, "RIGHT", 20, 0)
    copyHintText:SetText("Use CTRL+C to copy")
    copyHintText:SetTextColor(0.7, 0.7, 0.7, 1)  -- Gray color
    
    -- Twitch promotion in different color
    local twitchText = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    twitchText:SetPoint("LEFT", copyHintText, "RIGHT", 10, 0)
    twitchText:SetText("twitch.tv/soloqgpt")
    twitchText:SetTextColor(0.6, 0.8, 1.0, 1)  -- Light blue color
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, copyFrame, "UIPanelButtonTemplate")
    closeButton:SetPoint("BOTTOMRIGHT", copyFrame, "BOTTOMRIGHT", -15, buttonY)
    closeButton:SetSize(100, 25)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() 
        copyFrame:Hide()
    end)
end

-- Show copy frame (SIMPLE)
function ECC:ShowCopyFrame()
    if not copyFrame then
        ECC:CreateCopyFrame()
    end
    
    ECC:UpdateCopyFrameText()
    copyFrame:Show()
    
    -- Scroll to bottom
    C_Timer.After(0.1, function()
        if copyFrame.scrollFrame then
            local scrollRange = copyFrame.scrollFrame:GetVerticalScrollRange()
            if scrollRange and scrollRange > 0 then
                copyFrame.scrollFrame:SetVerticalScroll(scrollRange)
            end
        end
    end)
end

-- Show help (SIMPLE)
function ECC:ShowHelp()
    print("|cff00ff00=== EasyChatTWW Commands ===|r")
    print("|cffadd8e6/ecc|r - Opens the chat copy window")
    print("|cffadd8e6/ecc clear|r - Clears chat history")
    print("|cffadd8e6/ecc help|r - Shows this help")
    print("|cffadd8e6Copy Chat Button|r - Button at top right of chat window")
end

-- Slash commands (SIMPLE)
SLASH_EASYCHATCOPY1 = "/ecc"
SLASH_EASYCHATCOPY2 = "/easychat"
SlashCmdList["EASYCHATCOPY"] = function(msg)
    local command = string.lower(msg or "")
    
    if command == "" then
        ECC:ShowCopyFrame()
    elseif command == "clear" then
        chatHistory = {}
        print("|cff00ff00EasyChatTWW:|r Chat history cleared!")
    elseif command == "help" then
        ECC:ShowHelp()
    else
        print("|cffff0000EasyChatTWW:|r Unknown command. Use /ecc help")
    end
end 