local fovEnable = Menu.Checker("FOV", false, true)

local fov = Menu.Slider("FOV", 2, 1, 30)


local function draw_fov()
    if fovEnable:GetBool() then
        Renderer.DrawCircleFilled(Vector2D(Renderer.GetScreenSize().x/2, Renderer.GetScreenSize().y/2), fovEnable:GetColor(), 19 * fov:GetInt())
    end
end

Cheat.RegisterCallback("OnRenderer", draw_fov)