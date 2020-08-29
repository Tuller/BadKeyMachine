# BadKeyMachine-1.0

Bad key machine does the following

1. Makes the QuickKeybindFrame movable
1. Provides an API for activating and deactivating quick binding mode see (API usage)
1. Provides the slash commands `/badkeymachine`, `/bkm`, and `/bk` for activating quick binding mode

## API Usage

```lua
-- get an instance of the library
local BadKeyMachine = LibStub('BadKeyMachine-1.0')

-- enter into quick binding mode
local activated = BadKeyMachine:Activate()

-- exit from quick binding ode
local deactivated = BadKeyMachine:Deactivate()

-- toggle binding mode
BadKeyMachine:Toggle()

-- check to see if binding mode is currently active
local isActive = BadkeyMachine:IsActive()

-- watch for activation events
local Addon = {}

function Addon:QUICK_BINDING_MODE_ENABLED()
    print('Quick binding mode was enabled')
end

function Addon:QUICK_BINDING_MODE_DISABLED()
    print('Quick binding mode was disabled')
end

BadKeyMachine.RegisterCallback(Addon, 'QUICK_BINDING_MODE_ENABLED')
BadKeyMachine.RegisterCallback(Addon, 'QUICK_BINDING_MODE_DISABLED')
```
