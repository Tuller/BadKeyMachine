--------------------------------------------------------------------------------
-- Bad Key Machine
--
-- Enhances the standard Quick Keybinding Mode and provides an API for addons to
-- interact with it
--------------------------------------------------------------------------------

local MAJOR = 'BadKeyMachine-1.0'
local MINOR = 0

local BadKeyMachine = LibStub:NewLibrary(MAJOR, MINOR)
if not BadKeyMachine then
    return
end

-- frame for watching events
local function maybeCreateFrame(existing)
    if existing then
        return existing
    end

    local frame = CreateFrame('Frame')

    frame.minorVersion = MINOR
    frame:Hide()

    return frame
end

BadKeyMachine.frame = maybeCreateFrame(BadKeyMachine.frame)

-- callbacks
BadKeyMachine.callbacks = BadKeyMachine.callbacks or LibStub('CallbackHandler-1.0'):New(BadKeyMachine)

local function makeQuickKeybindFrameMovable()
    QuickKeybindFrame:SetClampedToScreen(true)

    local header = QuickKeybindFrame.Header
    header:EnableMouse(true)
    header:RegisterForDrag('LeftButton')

    header:SetScript(
        'OnDragStart',
        function(self)
            self.moving = true
            self:GetParent():StartMoving()
        end
    )

    header:SetScript(
        'OnDragStop',
        function(self)
            self.moving = nil
            self:GetParent():StopMovingOrSizing()
        end
    )
end

-- add support for binding more than one key via quick binding mode
local function addMultiBindingSupport()
    local function contains(value, ...)
        for i = 1, select('#', ...) do
            if select(i, ...) == value then
                return true
            end
        end

        return false
    end

    local function clearBindings(command, mode)
        local key = GetBindingKey(command, mode)
        while key do
            SetBinding(key, nil, mode)
            key = GetBindingKey(command, mode)
        end
    end

    local function setBinding(command, keyOrButton, mode)
        local keyPressed = GetConvertedKeyOrButton(keyOrButton)

        if not IsKeyPressIgnoredForBinding(keyPressed) then
            keyPressed = CreateKeyChordStringUsingMetaKeyState(keyPressed)

            return SetBinding(keyPressed, command, mode)
        end
    end

    local function setOutputText(...)
        KeyBindingFrame.outputText:SetFormattedText(...)
        QuickKeybindFrame.outputText:SetFormattedText(...)
    end

    local function clearOutputText()
        KeyBindingFrame.outputText:SetText('')
        QuickKeybindFrame.outputText:SetText('')
    end

    local function quickKeybindFrame_OnKeyDown(self, keyOrButton)
        local command = KeyBindingFrame.selected
        local mode = KeyBindingFrame.mode

        if command then
            if keyOrButton == 'ESCAPE' then
                clearBindings(command, mode)
                clearOutputText()
            else
                if setBinding(command, keyOrButton, mode) then
                    KeyBindingFrame:SetSelected(command)
                    setOutputText(KEY_BOUND)
                end
            end

            if self.mouseOverButton then
                self.mouseOverButton:QuickKeybindButtonSetTooltip()
            end
        elseif contains(keyOrButton, GetBindingKey('TOGGLEGAMEMENU', mode)) then
            ShowUIPanel(GameMenuFrame)
            self:CancelBinding()
        end

        if self.mouseOverButton then
            self.mouseOverButton:QuickKeybindButtonSetTooltip()
        end
    end

    local function quickKeybindFrame_OnMouseWheel(self, delta)
        if delta > 0 then
            quickKeybindFrame_OnKeyDown(self, 'MOUSEWHEELUP')
        else
            quickKeybindFrame_OnKeyDown(self, 'MOUSEWHEELDOWN')
        end
    end

    QuickKeybindFrame:SetScript('OnKeyDown', quickKeybindFrame_OnKeyDown)
    QuickKeybindFrame:SetScript('OnGamePadButtonDown', quickKeybindFrame_OnKeyDown)
    QuickKeybindFrame:SetScript('OnMouseWheel', quickKeybindFrame_OnMouseWheel)
    QuickKeybindFrame.OnMouseWheel = quickKeybindFrame_OnMouseWheel
end

-- adds support to quick binding tooltips for disaplaying multiple bindings
local function addMultiBindingSupportToQuickKeybindTooltips()
    local function map(func, arg, ...)
        local count = select('#', ...)

        if count == 0 then
            return func(arg)
        end

        return func(arg), map(func, ...)
    end

    -- add tooltip support for displaying more than one binding
    local function quickKeybindButtonSetTooltip(self, anchorToGameTooltip)
        local commandName = self.commandName
        if commandName and KeybindFrames_InQuickKeybindMode() then
            local parent = self:GetParent()

            if anchorToGameTooltip then
                QuickKeybindTooltip:SetOwner(GameTooltip, 'ANCHOR_TOP', 0, 10)
            elseif parent == MultiBarBottomRight or parent == MultiBarRight or parent == MultiBarLeft then
                QuickKeybindTooltip:SetOwner(self, 'ANCHOR_LEFT')
            else
                QuickKeybindTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            end

            GameTooltip_AddHighlightLine(QuickKeybindTooltip, GetBindingName(commandName))

            if GetBindingKey(commandName) then
                GameTooltip_AddInstructionLine(
                    QuickKeybindTooltip,
                    strjoin(' ', map(GetBindingText, GetBindingKey(commandName)))
                )
                GameTooltip_AddNormalLine(QuickKeybindTooltip, ESCAPE_TO_UNBIND)
            else
                GameTooltip_AddErrorLine(QuickKeybindTooltip, NOT_BOUND)
                GameTooltip_AddNormalLine(QuickKeybindTooltip, PRESS_KEY_TO_BIND)
            end

            QuickKeybindTooltip:Show()
        end
    end

    -- replace QuickKeybindButtonSetTooltip for existing frames
    local oldQuickKeybindButtonSetTooltip = QuickKeybindButtonTemplateMixin.QuickKeybindButtonSetTooltip
    local f = EnumerateFrames()
    while f do
        if f.QuickKeybindButtonSetTooltip == oldQuickKeybindButtonSetTooltip then
            f.QuickKeybindButtonSetTooltip = quickKeybindButtonSetTooltip
        end

        f = EnumerateFrames(f)
    end

    -- and also anything else that implements the mixin
    QuickKeybindButtonTemplateMixin.QuickKeybindButtonSetTooltip = quickKeybindButtonSetTooltip
end

local function addEnableDisableMessages()
    QuickKeybindFrame:HookScript(
        'OnShow',
        function()
            BadKeyMachine.callbacks:Fire('QUICK_BINDING_MODE_ENABLED', BadKeyMachine.activated)
        end
    )

    QuickKeybindFrame:HookScript(
        'OnHide',
        function()
            local wasActivated = BadKeyMachine.activated

            if wasActivated then
                BadKeyMachine.activated = nil

                -- if we manually triggered binding mode hide the
                -- KeyBindingFrame and GameMenuFrame when we exit
                if KeyBindingFrame:IsShown() then
                    HideUIPanel(KeyBindingFrame)
                end

                if GameMenuFrame:IsShown() then
                    HideUIPanel(GameMenuFrame)
                end
            end

            BadKeyMachine.callbacks:Fire('QUICK_BINDING_MODE_DISABLED', wasActivated)
        end
    )
end

local function onBindingsUILoaded()
    makeQuickKeybindFrameMovable()
    addMultiBindingSupport()
    addMultiBindingSupportToQuickKeybindTooltips()
    addEnableDisableMessages()
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function BadKeyMachine:Activate()
    if not self:IsActive() then
        if not IsAddOnLoaded('Blizzard_BindingUI') then
            LoadAddOn('Blizzard_BindingUI')
        end

        self.activated = true

        ShowUIPanel(KeyBindingFrame)
        KeyBindingFrame.quickKeybindButton:Click()
        return true
    end
end

-- turns off binding mode
function BadKeyMachine:Deactivate()
    if self:IsActive() then
        QuickKeybindFrame:CancelBinding()
        return true
    end
end

function BadKeyMachine:Toggle()
    if self:IsActive() then
        self:Deactivate()
    else
        self:Activate()
    end
end

function BadKeyMachine:IsActive()
    if QuickKeybindFrame then
        return QuickKeybindFrame:IsShown()
    end

    return false
end

function BadKeyMachine:SetBinding(command, keyOrButton, mode)
    SetBinding(command, keyOrButton, mode)
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

-- watch events
BadKeyMachine.frame:SetScript(
    'OnEvent',
    function(self, event, ...)
        if event == 'ADDON_LOADED' and ... == 'Blizzard_BindingUI' then
            self:UnregisterEvent(event)
            onBindingsUILoaded()
        end
    end
)

BadKeyMachine.frame:UnregisterAllEvents()
BadKeyMachine.frame:RegisterEvent('ADDON_LOADED')
BadKeyMachine.frame:RegisterEvent('PLAYER_LOGIN')

-- add slash commands
SlashCmdList['BadKeyMachine'] = function()
    BadKeyMachine:Toggle()
end
SLASH_BadKeyMachine1 = '/badkeymachine'
SLASH_BadKeyMachine2 = '/bk'
SLASH_BadKeyMachine3 = '/bkm'
