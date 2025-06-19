local menu_enabled = Menu.Checker("Enable Grenade Timers", true)

Renderer.LoadFontFromFile("TimerFont", "Verdana", 14, true)

local SMOKE_DURATION = 22.06
local MOLOTOV_DURATION = 7.03
local active_effects = {}

local UI_PADDING, UI_BORDER_THICKNESS, UI_TOP_ACCENT_HEIGHT = 6, 1, 2
local UI_TEXT_COLOR = Color(255, 255, 255, 255)
local UI_MAIN_BORDER_COLOR = Color(10, 10, 10, 255)
local UI_TOP_ACCENT_COLOR = Color(137, 154, 224, 255)
local UI_BACKGROUND_COLOR = Color(30, 30, 30, 220)

local function onEvent(event)
    if not menu_enabled:GetBool() then return end
    local name = event:GetName()

    if name == "smokegrenade_detonate" then
        table.insert(active_effects, {type="smoke", id=event:GetInt("entityid"), position=Vector(event:GetInt("x"),event:GetInt("y"),event:GetInt("z")), spawn_time=Globals:GetCurrentTime()})
    elseif name == "inferno_startburn" then
        table.insert(active_effects, {type="molotov", id=event:GetInt("entityid"), position=Vector(event:GetInt("x"),event:GetInt("y"),event:GetInt("z")), spawn_time=Globals:GetCurrentTime()})
    elseif name == "smokegrenade_expired" or name == "inferno_expire" or name == "inferno_extinguish" then
        local expired_id = event:GetInt("entityid")
        for i = #active_effects, 1, -1 do
            if active_effects[i].id == expired_id then table.remove(active_effects, i); return end
        end
    end
end

local function onRender()
    if not menu_enabled:GetBool() or #active_effects == 0 then return end

    local current_time = Globals:GetCurrentTime()
    local effects_to_remove = {}
    local screen = Renderer.GetScreenSize()

    for i, effect in ipairs(active_effects) do
        local duration = (effect.type == "smoke") and SMOKE_DURATION or MOLOTOV_DURATION
        local icon = (effect.type == "smoke") and "[S]" or "[M]"
        
        local time_elapsed = current_time - effect.spawn_time
        local time_remaining = duration - time_elapsed

        if time_remaining > 0 then
            local screen_pos = Renderer.WorldToScreen(effect.position)
            
            if screen_pos and screen_pos.x > 0 and screen_pos.y > 0 and screen_pos.x < screen.x and screen_pos.y < screen.y then
                local bg_width = 60
                local bg_height = 20

                local base_x = screen_pos.x - (bg_width / 2)
                local base_y = screen_pos.y - (bg_height / 2)

                Renderer.DrawRectFilled(Vector2D(base_x, base_y), Vector2D(base_x + bg_width, base_y + bg_height), UI_MAIN_BORDER_COLOR, 0)
                Renderer.DrawRectFilled(Vector2D(base_x + UI_BORDER_THICKNESS, base_y + UI_BORDER_THICKNESS), Vector2D(base_x + bg_width - UI_BORDER_THICKNESS, base_y + bg_height - UI_BORDER_THICKNESS), UI_BACKGROUND_COLOR, 0)
                
                Renderer.DrawRectFilled(Vector2D(base_x + UI_BORDER_THICKNESS, base_y + UI_BORDER_THICKNESS), Vector2D(base_x + bg_width - UI_BORDER_THICKNESS, base_y + UI_BORDER_THICKNESS + UI_TOP_ACCENT_HEIGHT), UI_TOP_ACCENT_COLOR, 0)

                local text = string.format("%s %.1f", icon, time_remaining)
                local text_pos = Vector2D(screen_pos.x, base_y + (bg_height / 2) - 6)
                Renderer.DrawText("TimerFont", text, text_pos, true, true, UI_TEXT_COLOR)

            end
        else
            table.insert(effects_to_remove, i)
        end
    end
    
    for i = #effects_to_remove, 1, -1 do
        table.remove(active_effects, effects_to_remove[i])
    end
end

Cheat.RegisterCallback("OnFireGameEvent", onEvent)
Cheat.RegisterCallback("OnRenderer", onRender)
print("Grenade timer script loaded.")
