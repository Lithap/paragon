-- Paragon/config.lua
-- default user-editable settings table
return {
    ------------------------------------------------------------------
    -- ⚙  ESP category  (demo placeholders)
    ------------------------------------------------------------------
    ESP = {
        Example      = false,        -- toggled by “Example Toggle”
        ExampleValue = 50,           -- set by “Example Slider”
        ExampleKey   = Enum.KeyCode.F
    },

    ------------------------------------------------------------------
    -- 🏃 Movement category  (empty for now – add later)
    ------------------------------------------------------------------
    Movement = {
        Fly = {
            Enabled = false,
            Speed   = 50,
            Key     = Enum.KeyCode.X
        }
    },

    ------------------------------------------------------------------
    -- 🔫 Combat category  (empty for now – add later)
    ------------------------------------------------------------------
    Combat = {
        Aimbot = {
            Enabled = false,
            FOV     = 90
        }
    },

    ------------------------------------------------------------------
    -- 🎛 UI & menu settings
    ------------------------------------------------------------------
    UI = {
        ToggleKey = Enum.KeyCode.RightShift   -- show / hide menu
    }
}
