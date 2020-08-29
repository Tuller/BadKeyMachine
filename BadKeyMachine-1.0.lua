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

local function addSlashCommands(lib)
    SlashCmdList['BadKeyMachine'] = function()
        lib:Toggle()
    end
    SLASH_BadKeyMachine1 = '/badkeymachine'
    SLASH_BadKeyMachine2 = '/bk'
    SLASH_BadKeyMachine3 = '/bkm'
end

local function initializeQuickKeybindFrame(lib)
    -- make the quick binding info frame movable
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

    QuickKeybindFrame:HookScript(
        'OnShow',
        function()
            lib.callbacks:Fire('QUICK_BINDING_MODE_ENABLED', lib.activated)
        end
    )

    QuickKeybindFrame:HookScript(
        'OnHide',
        function()
            local wasActivated = lib.activated

            if wasActivated then
                lib.activated = nil

                -- if we manually triggered binding mode hide the
                -- KeyBindingFrame and GameMenuFrame when we exit
                if KeyBindingFrame:IsShown() then
                    HideUIPanel(KeyBindingFrame)
                end

                if GameMenuFrame:IsShown() then
                    HideUIPanel(GameMenuFrame)
                end
            end

            lib.callbacks:Fire('QUICK_BINDING_MODE_DISABLED', wasActivated)
        end
    )
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

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

BadKeyMachine.frame:SetScript(
    'OnEvent',
    function(self, event, ...)
        if event == 'ADDON_LOADED' and ... == 'Blizzard_BindingUI' then
            self:UnregisterEvent(event)
            initializeQuickKeybindFrame(BadKeyMachine)
        elseif event == 'PLAYER_LOGIN' then
            self:UnregisterEvent(event)
            addSlashCommands(BadKeyMachine)
        end
    end
)

BadKeyMachine.frame:UnregisterAllEvents()
BadKeyMachine.frame:RegisterEvent('ADDON_LOADED')
BadKeyMachine.frame:RegisterEvent('PLAYER_LOGIN')
