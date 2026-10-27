# APEX_SYS V3.7 PLUS

A standalone Roblox GUI library built on the `SYSTEM_CONTROL // ENGINE` terminal style. It provides a draggable 392 × 397 window, scrollable tabs, toggles, inputs, full HSV color pickers, keybind controls, list cards, unload callbacks, and a fixed kill button without requiring external assets.

The original APEX_SYS V3.5 file is not modified. `ApexLibraryPlus.lua` is a separate extended library.

## Raw file

```text
https://raw.githubusercontent.com/DrayFKYT/Apex-Gui-library/refs/heads/main/ApexLibraryPlus.lua
```

## Requirements

- A Roblox executor environment with `loadstring` and `game:HttpGet`.
- Optional: `readfile`, `writefile`, and `isfile` for settings persistence.
- PC and touch devices are supported.

## Quick start

```lua
local ApexLibrary = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/DrayFKYT/Apex-Gui-library/refs/heads/main/ApexLibraryPlus.lua"
))()

local Apex = ApexLibrary.new({
    Title = "SYSTEM_CONTROL // ENGINE",
    BrandText = "APEX_SYS // RH",
    StatusText = "READY",
    HideKey = Enum.KeyCode.RightControl,
    AccentColor = Color3.fromRGB(255, 85, 0),
})

local MainTab = Apex:CreateTab("MAIN", "DASHBOARD")

MainTab:CreateButton("RUN ACTION", "Runs a sample action.", function()
    print("Action ran")
end)

MainTab:CreateToggle("SAMPLE TOGGLE", "Enables a sample feature.", false, function(enabled)
    print("Toggle:", enabled)
end)
```

Only call `ApexLibrary.new` once per script. If another script already loaded the library, reuse it:

```lua
local ApexLibrary = getgenv().ApexLibrary or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/DrayFKYT/Apex-Gui-library/refs/heads/main/ApexLibraryPlus.lua"
))()
```

## Library constructor

```lua
local Apex = ApexLibrary.new(config)
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `Title` | `string` | `"SYSTEM_CONTROL // ENGINE"` | Text shown in the window header. |
| `BrandText` | `string` | `"APEX_SYS // RH"` | Right-side footer label. |
| `StatusText` | `string` | `"READY"` | Initial footer status. |
| `HideKey` | `Enum.KeyCode` | `Enum.KeyCode.RightControl` | PC key used to hide/show the window. |
| `AccentColor` | `Color3` | `Color3.fromRGB(255, 85, 0)` | Initial accent color. |
| `SaveFileName` | `string` | `"ApexLibrary_Config.json"` | Config file name for this window. |

The window is created immediately. The first tab is selected automatically.

## Window API

| Method / property | Description |
| --- | --- |
| `Apex:CreateTab(name, sectionTitle)` | Creates a tab and returns a tab object. `name` is the tab label; `sectionTitle` is the header shown above the tab content. |
| `Apex:SelectTab(name, silent)` | Activates a tab by name. Pass `true` to skip the click sound. |
| `Apex:SetVisible(visible)` | Animates the window closed into the mobile button, or opens it again. |
| `Apex:GetAccentColor()` | Returns the current accent `Color3`. |
| `Apex:SetAccentColor(color)` | Updates all registered accent listeners and saves the setting. |
| `Apex:RegisterAccentListener(callback)` | Calls `callback(color)` whenever the accent color changes. |
| `Apex:RegisterUnloadCallback(callback)` | Calls `callback()` when the library unloads. |
| `Apex:SetStatus(text)` | Updates the footer status text until the next status change. |
| `Apex:Unload()` | Runs unload callbacks, closes pickers, and destroys the window, sounds, and mobile button. |
| `Apex:SaveSettings()` | Saves accent color, hide key, mobile lock state, and mobile button position. |
| `Apex:CloseColorPopups()` | Closes every open color-picker popup. |
| `Apex.Version` | `"APEX_SYS V3.7 PLUS"` |

`Apex:Unload()` destroys the library GUI and mobile button. It does **not** stop your own loops or connections automatically; register an unload callback for that:

```lua
Apex:RegisterUnloadCallback(function()
    -- Disconnect connections, stop loops, destroy custom instances.
end)
```

## Tab components

All tab methods use the colon syntax, for example `Tab:CreateToggle(...)`.

### Section label

```lua
Tab:CreateSectionLabel("VISUALS")
```

Returns the created `TextLabel`.

### Action button

```lua
local button = Tab:CreateButton("RUN", "Description", function()
    print("clicked")
end)
```

Returns an API:

| Method | Description |
| --- | --- |
| `button:SetText(text)` | Changes the button label. |
| `button:SetEnabled(enabled)` | Enables or disables the button and dims its text. |

### Toggle

```lua
local toggle = Tab:CreateToggle("FEATURE", "Description", false, function(enabled)
    print(enabled)
end)
```

Returns an API:

| Method | Description |
| --- | --- |
| `toggle:Get()` | Returns the current boolean. |
| `toggle:Set(state)` | Sets the state without firing the callback. |

### Toggle with number input

```lua
local control = Tab:CreateToggleWithInput(
    "AUTO FARM",
    "Description",
    false,
    24,
    function(enabled)
        print("toggle:", enabled)
    end,
    function(value)
        print("input:", value)
    end
)
```

Returns an API:

| Method | Description |
| --- | --- |
| `control:GetEnabled()` | Returns the toggle state. |
| `control:SetEnabled(state)` | Sets the toggle without firing the callback. |
| `control:GetValue()` | Returns the current number. |
| `control:SetValue(value)` | Sets the number without firing the input callback. |

### Toggle with color picker

```lua
local esp = Tab:CreateToggleWithColor(
    "ESP",
    "Description",
    false,
    Color3.fromRGB(255, 80, 80),
    function(enabled)
        print("toggle:", enabled)
    end,
    function(color)
        print("color:", color)
    end
)
```

Returns an API:

| Method | Description |
| --- | --- |
| `esp:GetEnabled()` | Returns the toggle state. |
| `esp:SetEnabled(state)` | Sets the toggle without firing the callback. |
| `esp:GetColor()` | Returns the selected `Color3`. |
| `esp:SetColor(color)` | Sets the color without firing the color callback. |

The color swatch opens a full HSV picker with an SV square, hue slider, RGB inputs, and an apply button. Open pickers close when the tab changes or the window is hidden.

### Standalone color picker

```lua
local colorPicker = Tab:CreateColorPicker(
    "PLAYER COLOR",
    "Description",
    Color3.fromRGB(0, 255, 120),
    function(color)
        print("applied:", color)
    end
)
```

Returns an API:

| Method | Description |
| --- | --- |
| `colorPicker:GetColor()` | Returns the selected `Color3`. |
| `colorPicker:SetColor(color)` | Sets the color without firing the callback. |
| `colorPicker:Open()` | Opens the picker. |
| `colorPicker:Close()` | Closes the picker. |

### Number input card

```lua
local input = Tab:CreateInputCard("DISTANCE", "Description", 16, function(value)
    print(value)
end)
```

Returns an API:

| Method | Description |
| --- | --- |
| `input:GetValue()` | Returns the current number. |
| `input:SetValue(value)` | Sets the number without firing the callback. |

Invalid text is rejected and the previous value is restored when the box loses focus.

### List card

```lua
local list = Tab:CreateListCard("PLAYERS", "Live list", 220)

list:Clear()
list:AddLabel("PlayerOne", Color3.fromRGB(180, 220, 255))
list:AddButton("Teleport", Color3.fromRGB(255, 85, 0), function()
    print("teleport")
end)
list:AddSpacer(8)

local scrollFrame = list:GetScrollFrame()
```

Returns an API:

| Method | Description |
| --- | --- |
| `list:Clear()` | Removes all child GUI objects. |
| `list:AddLabel(text, color, height)` | Adds a wrapped label. `height` is optional. Returns the label. |
| `list:AddButton(text, color, callback)` | Adds a styled button with a callback. Returns the button. |
| `list:AddSpacer(spacing)` | Adds vertical spacing. Returns the spacer. |
| `list:GetScrollFrame()` | Returns the underlying `ScrollingFrame`. |

### README / info card

```lua
local body = Tab:CreateReadMeCard("ABOUT", "Text shown inside the card.", 110)
```

Returns the body `TextLabel`, so the text can be updated later.

### Two-column layout

```lua
local columns = Tab:CreateColumnLayout(function(columnAPI)
    local left = columnAPI:CreateSideToggle("LEFT TOGGLE", false, function(enabled)
        print("left:", enabled)
    end)

    local right = columnAPI:CreateSideToggle("RIGHT TOGGLE", false, function(enabled)
        print("right:", enabled)
    end)
end)
```

`CreateColumnLayout` calls the supplied function with a column API and also returns that API. Each `CreateSideToggle` returns:

| Method | Description |
| --- | --- |
| `sideToggle:Get()` | Returns the current boolean. |
| `sideToggle:Set(state)` | Sets the state without firing the callback. |

### PC keybind card

```lua
local keybind = Tab:CreateKeybindCard()
```

Creates a card that lets the user press a new key to hide/show the window. The current key is saved to `ApexLibrary_Config.json`.

Returns an API:

| Method | Description |
| --- | --- |
| `keybind:GetKey()` | Returns the current `Enum.KeyCode`. |
| `keybind:GetButton()` | Returns the keybind `TextButton`. |

### Kill script button

```lua
Tab:CreateKillButton("KILL SCRIPT & CLEANUP", function()
    Apex:Unload()
end, 129)
```

Creates the red fixed kill button anchored above the footer. It is only visible while its tab is active and does not scroll with tab content. The optional third argument sets the active tab's content height (clamped to 40–160); omit it to use the default 160px.

Returns the `TextButton`.

### Info card

```lua
local info = Tab:CreateInfoCard("VERSION", Apex.Version)

info:SetValue("APEX_SYS V3.7 PLUS")
```

Returns an API with `SetValue(text)`.

## Configuration

The library uses:

```text
ApexLibrary_Config.json
```

It stores:

- Config version
- Accent color
- Hide key
- Mobile button lock state
- Mobile button position

Config version 1 and older are migrated to the terminal defaults so an old blue APEX config does not carry its accent or `P` hide key forward. Persistence is guarded with `pcall`. If the executor does not provide `readfile`, `writefile`, or `isfile`, the UI still works with defaults.

## UI behavior

- The window is a fixed 392 × 397 terminal panel with a 42px header, 38px tab bar, and 30px footer.
- The window is draggable from the header bar.
- Press the hide key (`RightControl` by default) to hide/show the window on PC.
- On touch devices, a draggable claw button opens and closes the window.
- Tabs divide the bar equally and show a 2px accent underline when active.
- With more than six tabs, the tab bar keeps each label readable and scrolls horizontally instead of squeezing every tab.
- Changing the accent color updates buttons, active tab lines, color swatches, status text, and other registered accents immediately.
- All corners are square except the mobile claw button.
- Open color popups close when switching tabs or hiding the window.
- Re-running the library destroys the previous `ApexSystemControl` and `ApexMobileButtonGui` instances before creating replacements.
- Callbacks are protected with `pcall`, so an error in a component callback does not break the rest of the UI.

## Version notes

`APEX_SYS V3.7 PLUS` adds:

- `SYSTEM_CONTROL // ENGINE` terminal skin: `#FF5500` accent, navy panels, square corners, orange active tabs, `LUAU` badge, and `STATUS` / brand footer
- `BrandText` and `StatusText` constructor options
- `SetStatus` and `Unload`
- `CreateKillButton`
- Optional content height for tabs with a fixed kill button
- Config version 2 migration from the old blue APEX theme
- Audio feedback removed; the library no longer uses sound assets
- Full SV square + hue slider + RGB color picker retained

`APEX_SYS V3.6 PLUS` added `CreateButton`, `CreateSectionLabel`, `CreateListCard`, component handles, fixed color-picker initialization, popup management, unload callbacks, and keybind listening guards.

The original APEX_SYS V3.5 library remains unchanged.
