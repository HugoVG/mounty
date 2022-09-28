MountxTLVData = {}

-- debugging https://www.wowace.com/projects/rarity/pages/faq/how-to-enable-and-disable-script-errors-lua-errors

-- local L = {}

local MountxTLVOptionsFrame = nil
local MountxTLVOptionsFrame_DebugMode = nil
local MountxTLVOptionsFrame_TaxiMode = nil
local MountxTLVOptionsFrame_DoNotFly = nil
local MountxTLVOptionsFrame_Random = nil
local MountxTLVOptionsFrame_ArmoredMin = nil
local MountxTLVOptionsFrame_Hello = nil

local MountxTLVOptionsFrame_Buttons = {}

local MountxTLVGround = 1
local MountxTLVFlying = 2
local MountxTLVWater = 3
local MountxTLVRepair = 4
local MountxTLVTaxi = 5
local MountxTLVShowOff = 6

local MountxTLVTypes = 6
local MountxTLVMounts = 10

local MountxTLVTypesLabel = {
    [1] = L["Ground"],
    [2] = L["Flying"],
    [3] = L["Water"],
    [4] = L["Repair"],
    [5] = L["Taxi"],
    [6] = L["Show off"]
}

local MountxTLVDebugForce = false

function MountxTLVChat(msg)

    if DEFAULT_CHAT_FRAME then

        DEFAULT_CHAT_FRAME:AddMessage("|cffa0a0ffMounty|r: " .. msg, 1, 1, 0)
    end
end

function MountxTLVDebug(msg)

    if (MountxTLVData.DebugMode or MountxTLVDebugForce) then
        MountxTLVChat(msg)
    end
end

function MountxTLVArmored()

    local curTotal = 0
    local maxTotal = 0

    for slot = 1, 20 do
        local curSlot, maxSlot = GetInventoryItemDurability(slot)
        if maxSlot then
            curTotal = curTotal + curSlot
            maxTotal = maxTotal + maxSlot
        end
    end

    local armored = 100 * curTotal / maxTotal

    MountxTLVDebug(L["debug armor"] .. " |cffa0a0ff" .. armored .. "%|r.")

    return armored
end

function MountxTLVSelect(typ)

    local ids = {}
    local count = 0
    local usable

    MountxTLVDataGlobal = MountxTLVData

    for i = 1, MountxTLVMounts do

        if (MountxTLVData.Mounts[typ][i] > 0) then

            mountID = C_MountJournal.GetMountFromSpell(MountxTLVData.Mounts[typ][i])
            mname, _, _, _, isUsable = C_MountJournal.GetMountInfoByID(mountID)

            MountxTLVDebug(L["debug usable"] .. mname .. " -> " .. tostring(isUsable))

            if (isUsable) then
                count = count + 1
                ids[count] = MountxTLVData.Mounts[typ][i]
            end
        end
    end

    if (count > 0) then

        if MountxTLVData.Random then
            picked = math.random(count)
        else
            if (MountxTLVData.Iterator[typ] < count) then
                MountxTLVData.Iterator[typ] = MountxTLVData.Iterator[typ] + 1
            else
                MountxTLVData.Iterator[typ] = 1
            end
            picked = MountxTLVData.Iterator[typ]
        end

        MountxTLVDebug(L["debug selected"] .. " " .. picked .. " / " .. count)

        return ids[picked]
    end

    MountxTLVDebug(L["debug not found"])
    return 0
end

function MountxTLVMountSpellID(mountID)

    _, spellID = C_MountJournal.GetMountInfoByID(mountID)

    return spellID
end

function MountxTLVMountUsableBySpellID(spellID)

    mountID = C_MountJournal.GetMountFromSpell(spellID)
    _, _, icon = C_MountJournal.GetMountInfoByID(mountID)
    return icon
end

function MountxTLVMount(category)

    local mountID = 0
    local typ = MountxTLVGround
    local spellID = 0

    if (category == "fly") then

        typ = MountxTLVFlying

    elseif (category == "water") then

        typ = MountxTLVWater

    elseif (category == "repair") then

        typ = MountxTLVRepair

    elseif (category == "taxi") then

        if not IsMounted() then
            SendChatMessage(MountxTLVData.Hello)
        end

        typ = MountxTLVTaxi

    elseif (category == "showoff") then

        typ = MountxTLVShowOff

    elseif (category == "random") then

        typ = 0
    end

    if (typ > 0) then

        spellID = MountxTLVSelect(typ)

        if (spellID > 0) then
            mountID = C_MountJournal.GetMountFromSpell(spellID)
        end
    end

    MountxTLVDebug(L["debug mount category"] .. category)
    MountxTLVDebug(L["debug mount type"] .. typ)
    MountxTLVDebug("spellID = " .. spellID)
    MountxTLVDebug("mountID = " .. mountID)

    C_MountJournal.SummonByID(mountID)
end

function MountxTLVKeyHandler(keypress)

    if (keypress == nil) then
        keypress = "auto"
    end

    MountxTLVDebug(L["debug key pressed"])
    MountxTLVDebug(L["debug key"] .. keypress)

    if keypress == "forceoff" then

        if IsMounted() then
            Dismount()
        end

        return

    elseif IsMounted() then

        MountxTLVDebug(L["debug mounted"])

        if not IsFlying() then
            Dismount()
        end

        if (keypress == "auto") then return end
    end

    if keypress == "repair" or keypress == "random" or keypress == "showoff" or keypress == "water" or keypress == "taxi" then

        MountxTLVDebug(L["debug special"])

        MountxTLVMount(keypress)

    else

        -- auto

        local alone = not IsInGroup()
        local flyable = IsFlyableArea()
        local swimming = IsSwimming()
        local taximode = MountxTLVData.TaxiMode
        local donotfly = MountxTLVData.DoNotFly

        MountxTLVDebug(L["debug magic"])

        if (donotfly) then

            flyable = false
        end

        local category = "ground"

        if (MountxTLVArmored() < MountxTLVData.ArmoredMin) then

            category = "repair"

        elseif (alone and flyable) then

            category = "fly"

        elseif (not alone and flyable and not taximode) then

            category = "fly"

        elseif (alone and not flyable and swimming) then

            category = "water"

        elseif (not alone and not flyable and swimming and not taximode) then

            category = "water"

        elseif (not alone and taximode) then

            category = "taxi"
        end

        MountxTLVDebug(L["debug category"] .. category)
        MountxTLVMount(category)
    end
end

function MountxTLVSetMount(self, button)

    local typ = self.MountxTLVTyp
    local index = self.MountxTLVIndex

    if (button == "LeftButton") then

        while (index > 1 and MountxTLVData.Mounts[typ][index - 1] == 0) do
            index = index - 1
        end

        infoType, mountID = GetCursorInfo()
        if (infoType == "mount") then
            ClearCursor()
            spellID = MountxTLVMountSpellID(mountID)

            local already = false

            for i = 1, MountxTLVMounts do
                if (MountxTLVData.Mounts[typ][i] == spellID) then
                    already = true
                end
            end

            if (spellID == 0) then

                MountxTLVDebug(L["debug fail"] .. " (spellID = 0): " .. infoType .. " " .. typ .. " " .. mountID)

            elseif (already) then

                MountxTLVDebug(L["debug fail"] .. " (" .. L["debug already"] .. "): " .. infoType .. " " .. typ .. " " .. mountID .. " " .. spellID)

            else

                MountyDebug(L["debug saved"] .. infoType .. " " .. typ .. " " .. index .. " " .. mountID .. " " .. spellID)
                MountyData.Mounts[typ][index] = spellID
                MountyOptionsRenderButtons()
            end
        end

    elseif (button == "RightButton") then

        MountyDebug(L["debug deleted"] .. typ .. " " .. index)

        for i = index, MountyMounts - 1 do
            MountyData.Mounts[typ][i] = MountyData.Mounts[typ][i + 1]
        end
        MountyData.Mounts[typ][MountyMounts] = 0

        MountyOptionsRenderButtons()
    end

    GameTooltip:Hide()

    --self:SetTexture("Interface\\Buttons\\UI-EmptySlot-White");
end

function MountyTooltip(self, motion)

    local typ = self.MountyTyp
    local index = self.MountyIndex

    local spellID = MountyData.Mounts[typ][index]

    if (spellID) then

        local mountID = C_MountJournal.GetMountFromSpell(spellID)
        local name = C_MountJournal.GetMountInfoByID(mountID)

        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:SetText(name)
        GameTooltip:Show()
    end
end

function MountyOptionsInit(self, event)

    if MountyData.DebugMode == nil then
        MountyData.DebugMode = false
    end

    if MountyData.TaxiMode == nil then
        MountyData.TaxiMode = false
    end

    if MountyData.DoNotFly == nil then
        MountyData.DoNotFly = false
    end

    if MountyData.Random == nil then
        MountyData.Random = false
    end

    if MountyData.ArmoredMin == nil then
        MountyData.ArmoredMin = 75
    end

    if MountyData.Hello == nil then
        MountyData.Hello = L["Taxi!"]
    end

    if MountyData.Mounts == nil then
        MountyData.Mounts = {}
    end

    if MountyData.Iterator == nil then
        MountyData.Iterator = {}
    end

    for t = 1, MountyTypes do

        if MountyData.Iterator[t] == nil then
            MountyData.Iterator[t] = 0
        end

        if MountyData.Mounts[t] == nil then
            MountyData.Mounts[t] = {}
        end

        for i = 1, MountyMounts do
            if (MountyData.Mounts[t][i] == nil) then
                MountyData.Mounts[t][i] = 0
            end
        end
    end

    self:UnregisterEvent("VARIABLES_LOADED")
    self:SetScript("OnEvent", nil)

    MountyOptionsInit = nil
end

function MountyOptionsOnShow()

    MountyOptionsFrame_DebugMode:SetChecked(MountyData.DebugMode)

    MountyOptionsFrame_TaxiMode:SetChecked(MountyData.TaxiMode)
    MountyOptionsFrame_DoNotFly:SetChecked(MountyData.DoNotFly)
    MountyOptionsFrame_Random:SetChecked(MountyData.Random)
    MountyOptionsFrame_ArmoredMin:SetValue(MountyData.ArmoredMin)

    MountyOptionsFrame_Hello:SetText(MountyData.Hello)

    MountyOptionsRenderButtons()
end

function MountyOptionsRenderButtons()

    local spellID
    local icon

    for t = 1, MountyTypes do

        for i = 1, MountyMounts do

            if (MountyData.Mounts[t][i] == 0) then
                MountyOptionsFrame_Buttons[t][i]:SetNormalTexture(nil)
                MountyOptionsFrame_Buttons[t][i]:Disable()
            else
                icon = GetSpellTexture(MountyData.Mounts[t][i])
                MountyOptionsFrame_Buttons[t][i]:SetNormalTexture(icon, "ARTWORK")
                MountyOptionsFrame_Buttons[t][i]:Enable()
            end
        end
    end
end

do

    local top
    local temp
    local spellID
    local infoType
    local mountID
    local icon

    -- Mounty options

    MountyOptionsFrame = CreateFrame("Frame", "MountyOptionsFrame", UIParent)
    MountyOptionsFrame:Hide()
    MountyOptionsFrame:SetWidth(300)
    MountyOptionsFrame:SetHeight(410)
    MountyOptionsFrame:SetFrameStrata("DIALOG")

    -- Title text

    temp = MountyOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    temp:SetPoint("TOPLEFT", 16, -16)
    temp:SetText(L["config options"])

    local top = 0
    local control_top_delta = 40

    -- Random checkbox

    top = -40

    MountyOptionsFrame_Random = CreateFrame("CheckButton", "MountyOptionsFrame_Random", MountyOptionsFrame, "InterfaceOptionsCheckButtonTemplate")
    MountyOptionsFrame_Random:SetPoint("TOPLEFT", 16, top)
    MountyOptionsFrame_RandomText:SetText(L["config random"])
    MountyOptionsFrame_Random:SetScript("OnClick", function(self)
        MountyData.Random = not MountyData.Random
        self:SetChecked(MountyData.Random)
    end)

    -- DoNotFly checkbox

    top = -40

    MountyOptionsFrame_DoNotFly = CreateFrame("CheckButton", "MountyOptionsFrame_DoNotFly", MountyOptionsFrame, "InterfaceOptionsCheckButtonTemplate")
    MountyOptionsFrame_DoNotFly:SetPoint("TOPLEFT", 96, top)
    MountyOptionsFrame_DoNotFlyText:SetText(L["config no flight"])
    MountyOptionsFrame_DoNotFly:SetScript("OnClick", function(self)
        MountyData.DoNotFly = not MountyData.DoNotFly
        self:SetChecked(MountyData.DoNotFly)
    end)

    -- TaxiMode checkbox

    top = -40

    MountyOptionsFrame_TaxiMode = CreateFrame("CheckButton", "MountyOptionsFrame_TaxiMode", MountyOptionsFrame, "InterfaceOptionsCheckButtonTemplate")
    MountyOptionsFrame_TaxiMode:SetPoint("TOPLEFT", 256, top)
    MountyOptionsFrame_TaxiModeText:SetText(L["config taxi"])
    MountyOptionsFrame_TaxiMode:SetScript("OnClick", function(self)
        MountyData.TaxiMode = not MountyData.TaxiMode
        self:SetChecked(MountyData.TaxiMode)
    end)

    -- DebugMode checkbox

    top = -40

    MountyOptionsFrame_DebugMode = CreateFrame("CheckButton", "MountyOptionsFrame_DebugMode", MountyOptionsFrame, "InterfaceOptionsCheckButtonTemplate")
    MountyOptionsFrame_DebugMode:SetPoint("TOPLEFT", 376, top)
    MountyOptionsFrame_DebugModeText:SetText(L["config debug"])
    MountyOptionsFrame_DebugMode:SetScript("OnClick", function(self)
        MountyData.DebugMode = not MountyData.DebugMode
        self:SetChecked(MountyData.DebugMode)
    end)

    -- Armored slider

    top = top - control_top_delta

    MountyOptionsFrame_ArmoredMin = CreateFrame("Slider", "MountyOptionsFrame_ArmoredMin", MountyOptionsFrame, "OptionsSliderTemplate")
    MountyOptionsFrame_ArmoredMin:SetWidth(335)
    MountyOptionsFrame_ArmoredMin:SetHeight(16)
    MountyOptionsFrame_ArmoredMin:SetPoint("TOPLEFT", 25, top)
    MountyOptionsFrame_ArmoredMinLow:SetText("50%")
    MountyOptionsFrame_ArmoredMinHigh:SetText("100%")
    MountyOptionsFrame_ArmoredMin:SetMinMaxValues(50, 100)
    MountyOptionsFrame_ArmoredMin:SetValueStep(1)
    MountyOptionsFrame_ArmoredMin:SetScript("OnValueChanged", function(self, value)
        MountyOptionsFrame_ArmoredMinText:SetFormattedText(L["config repair"], value)
        MountyData.ArmoredMin = value
    end)

    -- Taxi!

    top = top - control_top_delta - 10

    MountyOptionsFrame_Hello = CreateFrame("EditBox", "MountyOptionsFrame_Hello", MountyOptionsFrame, "InputBoxTemplate")
    MountyOptionsFrame_Hello:SetWidth(335)
    MountyOptionsFrame_Hello:SetHeight(16)
    MountyOptionsFrame_Hello:SetPoint("TOPLEFT", 25, top)
    MountyOptionsFrame_Hello:SetAutoFocus(false)
    MountyOptionsFrame_Hello:CreateFontString("MountyOptionsFrame_HelloLabel", "BACKGROUND", "GameFontNormalSmall")
    MountyOptionsFrame_HelloLabel:SetPoint("BOTTOMLEFT", MountyOptionsFrame_Hello, "TOPLEFT", 0, 1)
    MountyOptionsFrame_HelloLabel:SetText(L["config call passenger"])
    MountyOptionsFrame_Hello:SetScript("OnEnterPressed", function(self)
        MountyData.Hello = self:GetText()
        self:ClearFocus()
    end)

    -- Mounts

    for t = 1, MountyTypes do

        MountyOptionsFrame_Buttons[t] = {}

        top = top - control_top_delta

        temp = MountyOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        temp:SetPoint("TOPLEFT", 16, top - 10)
        temp:SetText(MountyTypesLabel[t])

        for i = 1, MountyMounts do

            MountyOptionsFrame_Buttons[t][i] = CreateFrame("Button", "MountyOptionsFrame_Buttons_t" .. t .. "_i" .. i, MountyOptionsFrame)
            MountyOptionsFrame_Buttons[t][i].MountyTyp = t
            MountyOptionsFrame_Buttons[t][i].MountyIndex = i
            MountyOptionsFrame_Buttons[t][i]:SetSize(32, 32)
            MountyOptionsFrame_Buttons[t][i]:SetDisabledTexture("Interface\\Buttons\\UI-EmptySlot", "ARTWORK")
            MountyOptionsFrame_Buttons[t][i]:GetDisabledTexture():SetTexCoord(0.15, 0.85, 0.15, 0.85);
            MountyOptionsFrame_Buttons[t][i]:SetHighlightTexture("Interface\\Buttons\\YellowOrange64_Radial", "ARTWORK")
            MountyOptionsFrame_Buttons[t][i]:SetPoint("TOPLEFT", 25 + i * 38, top)
            MountyOptionsFrame_Buttons[t][i]:SetScript("OnMouseUp", MountySetMount)
            MountyOptionsFrame_Buttons[t][i]:SetScript("OnEnter", MountyTooltip)
            MountyOptionsFrame_Buttons[t][i]:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
    end

    -- Add to Blizzard Interface Options

    MountyOptionsFrame.name = "Mounty"
    InterfaceOptions_AddCategory(MountyOptionsFrame)
end

MountyOptionsFrame:RegisterEvent("VARIABLES_LOADED")
MountyOptionsFrame:SetScript("OnEvent", MountyOptionsInit)
MountyOptionsFrame:SetScript("OnShow", MountyOptionsOnShow)

-- /mounty

SLASH_MOUNTY1 = "/mounty"
SlashCmdList["MOUNTY"] = function(message)

    if message == "debug on" then

        MountyData.DebugMode = true
        MountyChat(L["chat debug"] .. "|cff00f000" .. L["on"] .. "|r.")

    elseif message == "debug off" then

        MountyData.DebugMode = false
        MountyChat(L["chat debug"] .. "|cfff00000" .. L["off"] .. "|r.")

    elseif message == "fly on" then

        MountyData.DoNotFly = false
        MountyChat(L["chat fly"] .. "|cff00f000" .. L["on"] .. "|r.")

    elseif message == "fly off" then

        MountyData.DoNotFly = true
        MountyChat(L["chat fly"] .. "|cfff00000" .. L["off"] .. "|r.")

    elseif message == "random on" then

        MountyData.Random = false
        MountyChat(L["chat random"] .. "|cff00f000" .. L["on"] .. "|r.")

    elseif message == "random off" then

        MountyData.Random = true
        MountyChat(L["chat random"] .. "|cfff00000" .. L["off"] .. "|r.")

    elseif message == "taxi on" then

        MountyData.TaxiMode = true
        MountyChat(L["chat taxi"] .. "|cff00f000" .. L["on"] .. "|r.")

    elseif message == "taxi off" then

        MountyData.TaxiMode = false
        MountyChat(L["chat taxi"] .. "|cfff00000" .. L["off"] .. "|r.")

    elseif message ~= "" and message ~= nil then

        MountyMount(message)

    else

        InterfaceOptionsFrame_OpenToCategory("Mounty");
        InterfaceOptionsFrame_OpenToCategory("Mounty"); -- Muss 2 x aufgerufen werden ?!
    end
end
