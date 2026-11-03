# APEX_SYS V3.7 PLUS

A standalone Roblox GUI library built on the `SYSTEM_CONTROL // ENGINE` terminal style. It provides a draggable 392 × 397 window, scrollable tabs, toggles, inputs, full HSV color pickers, keybind controls, dynamic list cards, unload callbacks, and a fixed kill button without external assets.

The original APEX_SYS V3.5 file is not modified. `ApexLibraryPlus.lua` is a separate extended library.

## Contents

- [Raw file](#raw-file)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Complete example](#complete-example)
- [Library constructor](#library-constructor)
- [Window API](#window-api)
- [Tab API](#tab-api)
- [Components](#components)
- [Custom components](#custom-components)
- [Configuration](#configuration)
- [Theme](#theme)
- [Behavior notes](#behavior-notes)
- [UI behavior](#ui-behavior)
- [Version and revision notes](#version-and-revision-notes)
- [Troubleshooting](#troubleshooting)

## Raw file

```text
https://raw.githubusercontent.com/DrayFKYT/Apex-Gui-library/main/ApexLibraryPlus.lua
```

## Requirements

- A Roblox executor environment with `loadstring` and `game:HttpGet`.
- Optional: `readfile`, `writefile`, and `isfile` for settings persistence.
- PC and touch devices are supported. On PC the window keeps its native size while the smallest terminal labels use larger native font sizes; touch devices keep their original text sizes and fit scale.

## Quick start

```lua
local ApexLibrary = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/DrayFKYT/Apex-Gui-library/main/ApexLibraryPlus.lua?v=11"
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

Only create one window per script. Re-running `ApexLibrary.new` destroys the previous `ApexSystemControl` and mobile button before building the replacement. If another script already loaded the library, reuse it:

```lua
local ApexLibrary = getgenv().ApexLibrary or loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/DrayFKYT/Apex-Gui-library/main/ApexLibraryPlus.lua?v=11"
))()
```

## Complete example

```lua
local ApexLibrary = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/DrayFKYT/Apex-Gui-library/main/ApexLibraryPlus.lua?v=11"
))()

local Apex = ApexLibrary.new({
    Title = "MY SCRIPT // MENU",
    BrandText = "APEX_SYS // RH",
    StatusText = "READY",
    HideKey = Enum.KeyCode.RightControl,
    AccentColor = Color3.fromRGB(255, 85, 0),
})

-- DASHBOARD --------------------------------------------------------
local Main = Apex:CreateTab("MAIN", "DASHBOARD")

Main:CreateSectionLabel("WELCOME")
Main:CreateReadMeCard(
    "WELCOME // MY SCRIPT",
    "DEFAULT is RightControl on PC; tap the claw button on mobile to toggle. Edit colors in VISUALS.",
    76
)
Main:CreateInfoCard("AUTHOR", "YourName")

-- FEATURES ---------------------------------------------------------
local Features = Apex:CreateTab("FEATURES", "FEATURE CONTROLS")

Features:CreateToggle("ENABLED", "Turns the feature on or off.", false, function(state)
    print("Feature:", state)
end)

local runner = Features:CreateToggleWithInput(
    "AUTO RUN",
    "Runs at the selected interval.",
    false,
    10,
    function(state)
        print("Running:", state)
    end,
    function(value)
        print("Interval:", value)
    end
)

Features:CreateInputCard("DISTANCE", "How far to travel.", 16, function(value)
    print("Distance:", value)
end)

local esp = Features:CreateToggleWithColor(
    "ESP",
    "Highlights other players.",
    true,
    Color3.fromRGB(255, 80, 80),
    function(state)
        print("ESP:", state)
    end,
    function(color)
        print("ESP color:", color)
    end
)

local players = Features:CreateListCard("PLAYERS", "Live player list", 180)

local function refreshPlayers(names)
    players:Clear()
    if #names == 0 then
        players:AddLabel("No players found.", Color3.fromRGB(150, 150, 165))
        return
    end
    for _, name in ipairs(names) do
        players:AddLabel(name, Color3.fromRGB(240, 245, 255), 18)
        players:AddButton("TELEPORT // " .. name, Color3.fromRGB(255, 85, 0), function()
            print("Teleport to", name)
        end)
        players:AddSpacer(6)
    end
end

refreshPlayers({ "PlayerOne", "PlayerTwo" })

Features:CreateColumnLayout(function(columns)
    columns:CreateSideToggle("LEFT TOGGLE", false, function(state)
        print("left:", state)
    end)
    columns:CreateSideToggle("RIGHT TOGGLE", false, function(state)
        print("right:", state)
    end)
end)

-- VISUALS ----------------------------------------------------------
local Visuals = Apex:CreateTab("VISUALS", "COLOR SETTINGS")

local picker = Visuals:CreateColorPicker(
    "PLAYER COLOR",
    "Click the swatch to open the picker.",
    Color3.fromRGB(0, 255, 120),
    function(color)
        print("Applied color:", color)
    end
)

-- CONFIG -----------------------------------------------------------
local Config = Apex:CreateTab("CONFIG", "CONFIGURATION")

Config:CreateKeybindCard()
Config:CreateButton("APPLY", "Apply the current settings.", function()
    Apex:SetStatus("SETTINGS APPLIED")
end)
Config:CreateKillButton("KILL SCRIPT & CLEANUP", function()
    Apex:Unload()
end, 129)

Apex:RegisterUnloadCallback(function()
    print("Cleanup: stop loops and disconnect connections here")
end)

-- Keep handles for later updates:
-- runner:SetEnabled(true)
-- esp:SetColor(Color3.fromRGB(0, 255, 120))
-- picker:Open()
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
| `HideKey` | `Enum.KeyCode` | `Enum.KeyCode.RightControl` | Initial hide key. The shared profile overrides it after the first save. |
| `AccentColor` | `Color3` | `Color3.fromRGB(255, 85, 0)` | Initial accent color. The shared profile overrides it after the first save. |
| `SaveFileName` | `string` | `"ApexLibrary_Config.json"` | Deprecated and ignored. Library UI settings always use the shared profile. |

The window is created immediately. The first tab is selected automatically.

## Window API

All examples use `Apex` as the object returned by `ApexLibrary.new(config)`.

| Method / property | Returns | Description |
| --- | --- | --- |
| `Apex:CreateTab(name, sectionTitle)` | Tab object | Creates a tab. `name` is the tab label; `sectionTitle` is the header shown above its content. |
| `Apex:SelectTab(name, silent)` | `boolean` | Activates a tab by name. Returns `true` when found. `silent` is accepted for compatibility; the library does not play audio. |
| `Apex:SetVisible(visible)` | `nil` | Animates the window closed or open. The close animation shrinks toward the mobile claw when one exists. |
| `Apex:SetFullscreen(enabled)` | `nil` | Enters or leaves fullscreen. The window fills the viewport, tab content grows to match, and the UI scale is capped at 120%. |
| `Apex:GetAccentColor()` | `Color3` | Returns the current accent color. |
| `Apex:SetAccentColor(color)` | `nil` | Updates every registered accent listener and saves the setting. |
| `Apex:RegisterAccentListener(callback)` | `nil` | Calls `callback(color)` whenever the accent color changes. |
| `Apex:RegisterUnloadCallback(callback)` | `nil` | Calls `callback()` when `Apex:Unload()` runs. |
| `Apex:SetStatus(text)` | `nil` | Updates the footer status text. |
| `Apex:SaveSettings()` | `nil` | Saves the accent color, hide key, mobile button lock state, and mobile button position to the shared library profile. |
| `Apex:CloseColorPopups()` | `nil` | Closes every open color-picker popup. |
| `Apex:Unload()` | `nil` | Runs unload callbacks, closes pickers, and destroys the window and mobile button. |
| `Apex.Version` | `string` | `"APEX_SYS V3.7 PLUS"` |
| `Apex.LayoutRevision` | `number` | Current layout revision. Revision 12 adds the header fullscreen toggle. |
| `Apex.ConfigVersion` | `number` | Current profile schema version (`2`). |
| `Apex.ProfileFileName` | `string` | Shared library profile file (`"ApexLibrary_Config.json"`). |
| `Apex.Theme` | table | Shared terminal color palette. See [Theme](#theme). |
| `Apex.CurrentHideKey` | `Enum.KeyCode` | The active hide key. |
| `Apex.AccentColor` | `Color3` | The active accent color. |
| `Apex.IsUIVisible` | `boolean` | Whether the main window is currently open. |
| `Apex.IsFullscreen` | `boolean` | Whether the window is currently in fullscreen mode. |

`Apex:Unload()` destroys the library GUI, but it does **not** stop your own loops or disconnect your own events automatically. Register an unload callback for that:

```lua
Apex:RegisterUnloadCallback(function()
    -- Disconnect connections, stop loops, destroy custom instances.
end)
```

### Advanced window methods

These are used internally by the library. They are available if you build custom navigation, but most scripts do not need them.

| Method | Description |
| --- | --- |
| `Apex:RegisterColorPopup(popup)` | Adds a custom popup to the popup manager so it closes with the others. |
| `Apex:CloseColorPopupsExcept(exceptPopup)` | Closes all registered popups except the given one. |
| `Apex:GetTabScrollMax()` | Returns the maximum horizontal tab scroll offset. |
| `Apex:UpdateTabScrollButtons()` | Refreshes the visibility of the `<` / `>` tab arrows. |
| `Apex:ScrollTabs(direction)` | Scrolls the tab bar one full page. Use `-1` for left and `1` for right. |
| `Apex:ScrollTabsByPixels(delta)` | Scrolls the tab bar by a pixel amount. Mouse wheel input uses one tab width per notch. |
| `Apex:EnsureTabVisible(entry)` | Scrolls a tab entry into view. |
| `Apex:UpdateTabSizes()` | Recalculates tab widths after tabs are added. |
| `Apex:ActivateTab(entry, silent)` | Low-level tab switch that takes a tab entry rather than a tab name. |
| `Apex:UpdateWindowLayout()` | Refits the window and content area for the current viewport and fullscreen state. |
| `Apex:RefreshContentLayout()` | Recalculates tab content heights after a layout change. |
| `Apex:GetWindowSize()` | Returns the current window `UDim2` size. |

## Tab API

`Apex:CreateTab` returns a tab object. All tab methods use colon syntax.

| Method | Returns | Description |
| --- | --- | --- |
| `Tab:GetName()` | `string` | Returns the tab label. |
| `Tab:GetContainer()` | `ScrollingFrame` | Returns the tab's scrolling content container. Parent custom GUI objects here. |
| `Tab:Select()` | `nil` | Activates this tab. |
| `Tab:CreateSectionLabel(text)` | `TextLabel` | Adds a section heading. |
| `Tab:CreateButton(name, description, callback)` | Button API | Adds an action card with a `RUN` button. |
| `Tab:CreateToggle(name, description, initialState, callback)` | Toggle API | Adds an on/off card. |
| `Tab:CreateToggleWithInput(name, description, initialState, defaultValue, toggleCallback, inputCallback)` | Toggle + input API | Adds a toggle with a number box. |
| `Tab:CreateToggleWithColor(name, description, initialState, defaultColor, toggleCallback, colorCallback)` | Toggle + color API | Adds a toggle with a color swatch. |
| `Tab:CreateColorPicker(name, description, defaultColor, callback)` | Color picker API | Adds a standalone color swatch and popup. |
| `Tab:CreateInputCard(name, description, defaultValue, callback)` | Input API | Adds a standalone number input. |
| `Tab:CreateListCard(title, description, height)` | List API | Adds a scrollable list card. `height` defaults to `200`. |
| `Tab:CreateReadMeCard(title, bodyText, height)` | `TextLabel` | Adds an information card. `height` defaults to `90`. Returns the body label. |
| `Tab:CreateColumnLayout(callback)` | Column API | Adds a two-column row and calls `callback(columnAPI)`. |
| `Tab:CreateKeybindCard()` | Keybind API | Adds the PC hide-key picker card. |
| `Tab:CreateKeybindButton(name, description, options)` | Keybind action API | Adds an action card with a programmable key chip, optional clear `X`, and key-trigger callback. |
| `Tab:CreateKillButton(text, callback, contentHeight)` | `TextButton` | Adds the fixed red kill button above the footer. |
| `Tab:CreateInfoCard(labelName, valueText)` | Info API | Adds a two-column label/value row. |

Tab names should be unique if you use `Apex:SelectTab(name)`, because selection uses the first matching name.

## Components

### Section label

```lua
local label = Tab:CreateSectionLabel("VISUALS")
```

Returns the created `TextLabel`. Use it to separate groups of cards.

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

The card title stays on the left; the right-side `RUN` button fires the callback.

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

The input callback fires when the number box loses focus and the text is valid. Invalid text is rejected and the previous value is restored.

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

The swatch opens a full HSV picker with an SV square, hue slider, RGB inputs, and an apply button. The color callback fires when **APPLY COLOR** is pressed, not while dragging.

### Standalone color picker

```lua
local picker = Tab:CreateColorPicker(
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
| `picker:GetColor()` | Returns the selected `Color3`. |
| `picker:SetColor(color)` | Sets the color without firing the callback. |
| `picker:Open()` | Opens the picker. |
| `picker:Close()` | Closes the picker. |

Open pickers close automatically when the tab changes or the window is hidden.

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
| `list:Clear()` | Removes all child GUI objects and resets the layout order. |
| `list:AddLabel(text, color, height)` | Adds a wrapped label. `height` is optional; omit it for automatic height. Returns the `TextLabel`. |
| `list:AddButton(text, color, callback)` | Adds a styled button with a callback. Returns the `TextButton`. |
| `list:AddSpacer(spacing)` | Adds vertical spacing. `spacing` defaults to `4`. Returns the spacer `Frame`. |
| `list:GetScrollFrame()` | Returns the underlying `ScrollingFrame` for advanced customization. |

Typical live-list pattern:

```lua
local function refresh(names)
    list:Clear()
    for _, name in ipairs(names) do
        list:AddLabel(name, Color3.fromRGB(240, 245, 255), 18)
        list:AddButton("TELEPORT // " .. name, Color3.fromRGB(255, 85, 0), function()
            print("Teleport to", name)
        end)
        list:AddSpacer(6)
    end
end
```

### README / info card

```lua
local body = Tab:CreateReadMeCard("ABOUT", "Text shown inside the card.", 110)
```

Returns the body `TextLabel`, so the text can be updated later:

```lua
body.Text = "Updated text"
```

The third argument is the card height and defaults to `90`.

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

The row is 56px tall and splits into two equal cards.

### PC keybind card

```lua
local keybind = Tab:CreateKeybindCard()
```

Creates a card that lets the user press a new key to hide/show the window. The current key is saved to the active config file.

Returns an API:

| Method | Description |
| --- | --- |
| `keybind:GetKey()` | Returns the current `Enum.KeyCode`. |
| `keybind:GetButton()` | Returns the keybind `TextButton`. |

Press the keybind button, then press a keyboard key to bind it. `Escape` cancels. Listening automatically stops after 5 seconds if no key is pressed.

### Keybind action row

```lua
local ragdoll = Tab:CreateKeybindButton("RAGDOLL", "Tumble the current creature.", {
    Key = Enum.KeyCode.R,
    Required = false,
    ActionText = "RAGDOLL",
    OnActivated = function()
        print("ragdoll")
    end,
    OnKeyChanged = function(key)
        print(key and key.Name or "NONE")
    end
})
```

Adds an action card with a key chip, an adjacent clear `X`, and a right-side action button. Options:

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `Key` | `Enum.KeyCode` / `string` / `false` | `nil` | Initial binding. `false` or `nil` starts at `NONE`. |
| `Required` | `boolean` | `false` | When true, the binding cannot be cleared and no `X` is shown. |
| `ShowAction` | `boolean` | `true` | Set to false to omit the right-side action button, leaving a keybind-only row. |
| `TriggerOnKey` | `boolean` | `true` | Fires `OnActivated` when the bound key is pressed. |
| `ActionText` | `string` | `"RUN"` | Label on the right-side action button. |
| `OnActivated` | `function` | `nil` | Runs on action-button click, or on the bound key when `TriggerOnKey` is true. |
| `OnKeyChanged` | `function` | `nil` | Called with the new `Enum.KeyCode`, or `nil` when cleared. |

Returns an API:

| Method | Description |
| --- | --- |
| `row:GetKey()` | Returns the current `Enum.KeyCode`, or `nil` for `NONE`. |
| `row:SetKey(key)` | Sets the binding (required rows fall back to the current hide key when cleared). |
| `row:GetButton()` | Returns the action `TextButton`, or `nil` when `ShowAction = false`. |
| `row:GetKeybindButton()` | Returns the key chip `TextButton`. |
| `row:GetClearButton()` | Returns the `X` clear button. |
| `row:SetText(text)` | Changes the action button label. |
| `row:SetEnabled(enabled)` | Enables or disables the action button. |

Click the key chip and press a keyboard key to bind it. `Escape` cancels. Clicking `X` (optional rows only) clears the binding to `NONE`. Key triggers are ignored while a textbox is focused.

### Kill script button

```lua
Tab:CreateKillButton("KILL SCRIPT & CLEANUP", function()
    Apex:Unload()
end, 129)
```

Creates the red fixed kill button anchored above the footer. It is only visible while its tab is active and does not scroll with tab content. The optional third argument sets the active tab's content height (clamped to 40–160); omit it to use the default 160px.

If no callback is provided, the button calls `Apex:Unload()` automatically. Returns the `TextButton`.

### Info card

```lua
local info = Tab:CreateInfoCard("VERSION", Apex.Version)

info:SetValue("APEX_SYS V3.7 PLUS")
```

Returns an API:

| Method | Description |
| --- | --- |
| `info:SetValue(text)` | Updates the right-side value. |

## Custom components

Use `Tab:GetContainer()` to parent your own GUI objects into the tab's scrolling content. The container already has a vertical `UIListLayout`, so set `LayoutOrder` on custom elements.

```lua
local container = Tab:GetContainer()

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0, 20)
label.BackgroundTransparency = 1
label.Font = Enum.Font.RobotoMono
label.Text = "CUSTOM ROW"
label.TextColor3 = Apex.Theme.Muted
label.TextSize = 12
label.TextXAlignment = Enum.TextXAlignment.Left
label.LayoutOrder = 100
label.Parent = container
```

For custom content inside a list card, use `list:GetScrollFrame()` and parent your objects there. Custom GUI objects are not managed by the library, so clean them up yourself if needed.

## Configuration

APEX keeps one library-wide profile that every script using the library shares:

```text
ApexLibrary_Config.json
```

It stores:

- Config version
- Accent color
- Hide key
- Mobile button lock state
- Mobile button position

Customize the accent, hide key, or mobile claw button once and every APEX menu opens with those settings, even when a different script created it. Settings save immediately, and each new window reads the profile fresh.

`SaveFileName` is deprecated and ignored. Library UI settings always use the shared profile so they cannot be split per script. Script-specific settings (toggles, ESP colors, and so on) should stay in that script's own config file, such as `DandysWorld_Apex_Config.json`.

Config version 1 and older are migrated to the terminal defaults so an old blue APEX config does not carry its accent or `P` hide key forward. Persistence is guarded with `pcall`. If the executor does not provide `readfile`, `writefile`, or `isfile`, the UI still works with defaults.

On PC there is no mobile claw button, so saving there preserves the last mobile button position instead of replacing it with the default. This keeps the claw where you left it when you switch between PC and touch devices.

## Theme

The shared terminal palette is available as `ApexLibrary.Theme` (also `Apex.Theme`):

| Key | Color |
| --- | --- |
| `Window` | `#1A1D23` |
| `Header` / `Card` | `#222630` |
| `TabBar` | `#16181D` |
| `TabActive` | `#191C22` |
| `Input` / `Footer` | `#121417` |
| `Border` | `#2E3440` |
| `Divider` | `#252932` |
| `Text` | `#FFFFFF` |
| `Muted` | `#8A92A0` |
| `Section` | `#838998` |
| `Body` | `#A0A8B6` |
| `Green` | `#34D399` |
| `Red` | `#FF6B6B` |
| `RedDim` | `#FCA5A5` |
| `RedBg` | `#2C1519` |
| `RedBorder` | `#5C1F24` |
| `Accent` | `#FF5500` |
| `Thumb` | `#7C8595` |

All library strokes are border-only, so button and input text stays clean instead of receiving an outline.

## Behavior notes

- Component callbacks are protected with `pcall`; an error in one callback does not break the rest of the UI.
- `Set` methods update visuals and state without firing their component callback.
- Color callbacks fire when **APPLY COLOR** is pressed. `SetColor` updates the stored color without firing the callback.
- Toggle-with-input callbacks fire on focus lost, not on every keystroke.
- `Apex:SetAccentColor` updates registered accents immediately and saves the config.
- `Apex:Unload` does not stop your own loops or connections; use `RegisterUnloadCallback`.
- Tab content is a `ScrollingFrame` with automatic vertical canvas sizing.

## UI behavior

- The window is a fixed 392 × 397 terminal panel with a 42px header, 38px tab bar, and 30px footer.
- The window is draggable from the header bar.
- Press the hide key (`RightControl` by default) to hide/show the window on PC.
- On touch devices, a draggable claw button opens and closes the window.
- Tabs divide the bar equally and show a 2px accent underline when active. Four tabs fit at once; if a script adds more, each tab stays 87px wide with 13px desktop text.
- With more than four tabs, the tab bar keeps each label readable and scrolls horizontally instead of squeezing every tab. Left/right arrow buttons appear on each side and move one full page; on PC the mouse wheel scrolls one tab per notch. Selecting a tab scrolls it into view.
- The tab bar has a thin horizontal scrollbar under it, matching the vertical content scrollbar.
- Changing the accent color updates buttons, active tab lines, color swatches, status text, and other registered accents immediately.
- The accent color, hide key, mobile lock state, and mobile button position are stored in one shared library profile, so the same customization follows every script that uses APEX.
- All corners are square except the mobile claw button.
- Open color popups close when switching tabs or hiding the window.
- Re-running the library destroys the previous `ApexSystemControl` and `ApexMobileButtonGui` instances before creating replacements.
- PC text uses whole-pixel native sizes instead of fractional UI scaling, so the text stays sharp. Touch devices keep their original sizes.

## Version and revision notes

`APEX_SYS V3.7 PLUS` adds:

- `SYSTEM_CONTROL // ENGINE` terminal skin: `#FF5500` accent, navy panels, square corners, orange active tabs, `LUAU` badge, and `STATUS` / brand footer
- `BrandText` and `StatusText` constructor options
- `SetStatus` and `Unload`
- `CreateKillButton`
- Optional content height for tabs with a fixed kill button
- Config version 2 migration from the old blue APEX theme
- Audio feedback removed; the library does not use sound assets
- Full SV square + hue slider + RGB color picker retained
- Header `FULL` / `EXIT` toggle: expands the window to the screen, grows the scrollable tabs, and caps text scaling at 120% so it stays readable without ballooning
- The mobile claw toggle renders above the fullscreen window so mobile players cannot get trapped behind it

Recent layout revisions:

- Revision 5: PC uses larger native font sizes; whole-window 120% scaling was removed.
- Revision 6: PC card descriptions match the larger native text sizes.
- Revision 7: every `UIStroke` is border-only, so button text is no longer outlined.
- Revision 8: four tabs fit at once with larger tab text, horizontal arrows scroll one page, and the PC mouse wheel scrolls the tab bar one tab per notch.
- Revision 9: accent color, hide key, mobile lock, and mobile button position use one shared profile across every script; desktop saves no longer reset the mobile button position.
- Revision 10: `CreateKeybindButton` adds action cards with programmable key chips; optional rows can be cleared with `X`, while required rows cannot be cleared and never show it.
- Revision 11: `ShowAction = false` turns a keybind action row into a keybind-only row, removing the right-side action button.
- Revision 12: the header gains a `FULL` / `EXIT` toggle. Fullscreen expands the window and scrolling tab content to fit the viewport, scales the UI only modestly (maximum 120%), and keeps the mobile claw toggle above the window.

`APEX_SYS V3.6 PLUS` added `CreateButton`, `CreateSectionLabel`, `CreateListCard`, component handles, fixed color-picker initialization, popup management, unload callbacks, and keybind listening guards.

The original APEX_SYS V3.5 library remains unchanged.

## Troubleshooting

**The window does not appear.**
- Confirm the executor supports `game:HttpGet` and `loadstring`.
- Check that another script did not call `Apex:Unload()`.
- Re-run the loader; it destroys stale `ApexSystemControl` instances first.

**My callbacks do not fire.**
- `Set` methods intentionally do not fire callbacks.
- Color callbacks fire on **APPLY COLOR**, not while dragging.
- Input callbacks fire when the number box loses focus.

**Settings do not persist.**
- The executor must provide `readfile`, `writefile`, and `isfile`.
- Library UI settings are stored in the shared `ApexLibrary_Config.json` profile. Do not use `SaveFileName` to try to split them per script.

**Text is too small on PC.**
- Use library revision 5 or newer. It selects larger whole-pixel font sizes without scaling the window.
