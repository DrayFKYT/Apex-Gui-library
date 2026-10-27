# APEX_SYS V3.6 PLUS

A standalone Roblox GUI library built on the APEX_SYS visual style. It provides a draggable window, scrollable tabs, toggles, inputs, color pickers, keybind controls, list cards, and unload callbacks without requiring external assets.

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
    Title = "MY SCRIPT // APEX",
    HideKey = Enum.KeyCode.P,
    AccentColor = Color3.fromRGB(0, 160, 255),
})

local MainTab = Apex:CreateTab("MAIN", "MAIN")

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
| `Title` | `string` | `"APEX // LIBRARY"` | Text shown in the window header. |
| `HideKey` | `Enum.KeyCode` | `Enum.KeyCode.P` | PC key used to hide/show the window. |
| `AccentColor` | `Color3` | `Color3.fromRGB(0, 160, 255)` | Initial accent color. |

The window is created immediately. The first tab is selected automatically.

## Window API

| Method | Description |
| --- | --- |
| `Apex:CreateTab(name, sectionTitle)` | Creates a tab and returns a tab object. `name` is the tab label; `sectionTitle` is the header shown above the tab content. |
| `Apex:SetVisible(visible)` | Animates the window closed into the mobile button, or opens it again. |
| `Apex:GetAccentColor()` | Returns the current accent `Color3`. |
| `Apex:SetAccentColor(color)` | Updates all registered accent listeners and saves the setting. |
| `Apex:RegisterAccentListener(callback)` | Calls `callback(color)` whenever the accent color changes. |
| `Apex:RegisterUnloadCallback(callback)` | Calls `callback()` when the user clicks **UNLOAD LIBRARY**. |
| `Apex:SaveSettings()` | Saves accent color, hide key, mobile lock state, and mobile button position. |
| `Apex:CloseColorPopups()` | Closes every open color-picker popup. |
| `Apex.Version` | `"APEX_SYS V3.6 PLUS"` |

The unload button destroys the library GUI and mobile button. It does **not** stop your own loops or connections automatically; register an unload callback for that:

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

The color swatch opens a full HSV picker with RGB inputs and an apply button. Open pickers close when the tab changes or the window is hidden.

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
list:AddButton("Teleport", Color3.fromRGB(0, 160, 255), function()
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
Tab:CreateKeybindCard()
```

Creates a card that lets the user press a new key to hide/show the window. The current key is saved to `ApexLibrary_Config.json`.

### Info card

```lua
local info = Tab:CreateInfoCard("VERSION", Apex.Version)

info:SetValue("APEX_SYS V3.6 PLUS")
```

Returns an API with `SetValue(text)`.

## Configuration

The library uses:

```text
ApexLibrary_Config.json
```

It stores:

- Accent color
- Hide key
- Mobile button lock state
- Mobile button position

Persistence is guarded with `pcall`. If the executor does not provide `readfile`, `writefile`, or `isfile`, the UI still works with defaults.

## UI behavior

- The window is draggable from the header bar.
- Press the hide key (`P` by default) to hide/show the window on PC.
- On touch devices, a draggable claw button opens and closes the window.
- Changing the accent color updates buttons, active tab lines, color swatches, and other registered accents immediately.
- Open color popups close when switching tabs or hiding the window.
- Re-running the library destroys the previous `ApexSystemControl` and `ApexMobileButtonGui` instances before creating replacements.
- Callbacks are protected with `pcall`, so an error in a component callback does not break the rest of the UI.

## Version notes

`APEX_SYS V3.6 PLUS` adds:

- `CreateButton`
- `CreateSectionLabel`
- `CreateListCard`
- Component handles for toggles, inputs, colors, buttons, and info cards
- Fixed color-picker initialization and RGB input handling
- Color popup manager that closes pickers on tab switch or hide
- Unload callbacks for user scripts
- Keybind listening guard

The original APEX_SYS V3.5 library remains unchanged.
