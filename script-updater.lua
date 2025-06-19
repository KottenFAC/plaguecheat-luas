-- @version: 1.5
-- @author: kotten
local SCRIPT_URL = "https://raw.githubusercontent.com/KottenFAC/plaguecheat-luas/refs/heads/main/script-updater.lua"
local SCRIPT_PATH = "C:\\plaguecheat.cc\\" .. Cheat.GetScriptName()
local UPDATE_INTERVAL = 3600

local menu_auto_update_enabled = Menu.Checker("Enable Auto-Update", false)

local ffi = require("ffi")
ffi.cdef[[
    typedef unsigned long DWORD; typedef void* HINTERNET; typedef void* LPVOID; typedef const char* LPCSTR; typedef void* HANDLE;
    static const int INTERNET_FLAG_RELOAD = 0x80000000; static const int INTERNET_FLAG_NO_CACHE_WRITE = 0x04000000;
    HINTERNET InternetOpenA(LPCSTR, DWORD, LPCSTR, LPCSTR, DWORD);
    HINTERNET InternetOpenUrlA(HINTERNET, LPCSTR, LPCSTR, DWORD, DWORD, DWORD);
    bool InternetReadFile(HINTERNET, LPVOID, DWORD, DWORD*);
    bool InternetCloseHandle(HINTERNET);
    static const DWORD GENERIC_READ = 0x80000000; static const DWORD GENERIC_WRITE = 0x40000000;
    static const DWORD OPEN_EXISTING = 3; static const DWORD CREATE_ALWAYS = 2; static const int FILE_ATTRIBUTE_NORMAL = 0x80;
    HANDLE CreateFileA(LPCSTR, DWORD, DWORD, LPVOID, DWORD, DWORD, HANDLE);
    bool ReadFile(HANDLE, LPVOID, DWORD, DWORD*, LPVOID);
    bool WriteFile(HANDLE, LPCSTR, DWORD, DWORD*, LPVOID);
    bool CloseHandle(HANDLE);
    DWORD GetFileSize(HANDLE, DWORD*);
]]

local wininet = ffi.load("wininet")
local kernel32 = ffi.load("kernel32")

local function read_file(path)
    local hFile = kernel32.CreateFileA(path, ffi.C.GENERIC_READ, 1, nil, ffi.C.OPEN_EXISTING, ffi.C.FILE_ATTRIBUTE_NORMAL, nil)
    if hFile == nil or hFile == ffi.cast("HANDLE", -1) then
        print("Error: Could not open file for reading at " .. path)
        return nil
    end
    local file_size = kernel32.GetFileSize(hFile, nil)
    if file_size == 0 then
        kernel32.CloseHandle(hFile)
        return ""
    end
    local buffer = ffi.new("char[?]", file_size)
    local bytes_read = ffi.new("DWORD[1]")
    kernel32.ReadFile(hFile, buffer, file_size, bytes_read, nil)
    kernel32.CloseHandle(hFile)
    return ffi.string(buffer, bytes_read[0])
end

local function write_file(path, content)
    local hFile = kernel32.CreateFileA(path, ffi.C.GENERIC_WRITE, 0, nil, ffi.C.CREATE_ALWAYS, ffi.C.FILE_ATTRIBUTE_NORMAL, nil)
    if hFile == nil or hFile == ffi.cast("HANDLE", -1) then return false end
    local bytes_written = ffi.new("DWORD[1]")
    kernel32.WriteFile(hFile, content, #content, bytes_written, nil)
    kernel32.CloseHandle(hFile)
    return bytes_written[0] == #content
end

local function http_get(url)
    local hInternet = wininet.InternetOpenA("LuaScriptUpdater/1.0", 1, nil, nil, 0)
    if hInternet == nil then return nil end
    local headers = "Cache-Control: no-cache, no-store, must-revalidate\r\nPragma: no-cache\r\nExpires: 0\r\n"
    local hUrl = wininet.InternetOpenUrlA(hInternet, url, headers, #headers, ffi.C.INTERNET_FLAG_RELOAD + ffi.C.INTERNET_FLAG_NO_CACHE_WRITE, 0)
    if hUrl == nil then wininet.InternetCloseHandle(hInternet); return nil end
    local response_body = ""
    local buffer = ffi.new("char[4096]")
    local bytesRead = ffi.new("DWORD[1]")
    while wininet.InternetReadFile(hUrl, buffer, 4096, bytesRead) and bytesRead[0] > 0 do
        response_body = response_body .. ffi.string(buffer, bytesRead[0])
    end
    wininet.InternetCloseHandle(hUrl)
    wininet.InternetCloseHandle(hInternet)
    return response_body
end

local function get_self_version()
    local content = read_file(SCRIPT_PATH)
    if not content then return "0.0" end
    local version = content:match("%-%-%s*@version%s*:%s*([%d%.]+)")
    return version or "0.0"
end

Renderer.LoadFontFromFile("UpdaterFont", "Arial", 16, true)
local NOTIFICATION_FONT = "UpdaterFont"
local NOTIFICATION_FONT_HEIGHT = 16

local character_width_map = { [' '] = 5, ['!'] = 5, ['"'] = 6, ['#'] = 10, ['%'] = 15, ['&'] = 10, ['\''] = 4, ['('] = 6, [')'] = 6, ['*'] = 8, ['+'] = 10, [','] = 5, ['-'] = 6, ['.'] = 5, ['/'] = 6, ['0'] = 8, ['1'] = 8, ['2'] = 8, ['3'] = 8, ['4'] = 8, ['5'] = 8, ['6'] = 8, ['7'] = 8, ['8'] = 8, ['9'] = 8, [':'] = 6, [';'] = 6, ['<'] = 10, ['='] = 10, ['>'] = 10, ['?'] = 7, ['@'] = 14, ['A'] = 9, ['B'] = 9, ['C'] = 9, ['D'] = 10, ['E'] = 8, ['F'] = 8, ['G'] = 10, ['H'] = 10, ['I'] = 6, ['J'] = 6, ['K'] = 9, ['L'] = 7, ['M'] = 12, ['N'] = 10, ['O'] = 10, ['P'] = 8, ['Q'] = 10, ['R'] = 9, ['S'] = 8, ['T'] = 9, ['U'] = 10, ['V'] = 9, ['W'] = 13, ['X'] = 9, ['Y'] = 8, ['Z'] = 8, ['['] = 6, ['\\'] = 6, [']'] = 6, ['^'] = 10, ['_'] = 8, ['`'] = 8, ['a'] = 8, ['b'] = 8, ['c'] = 7, ['d'] = 8, ['e'] = 8, ['f'] = 5, ['g'] = 8, ['h'] = 8, ['i'] = 4, ['j'] = 5, ['k'] = 7, ['l'] = 4, ['m'] = 12, ['n'] = 8, ['o'] = 8, ['p'] = 8, ['q'] = 8, ['r'] = 6, ['s'] = 7, ['t'] = 5, ['u'] = 8, ['v'] = 7, ['w'] = 11, ['x'] = 7, ['y'] = 7, ['z'] = 7, ['{'] = 7, ['|'] = 6, ['}'] = 7, ['~'] = 10 }
local default_char_width = 8

function ApproxTextWidth(text)
    local total_width = 0
    text = tostring(text or "")
    for i = 1, #text do
        local char = text:sub(i, i)
        total_width = total_width + (character_width_map[char] or default_char_width)
    end
    return total_width
end

local active_notifications = {}
local NOTIFICATION_DURATION = 8.0
local FADE_OUT_TIME = 1.5

local COLOR_BG = Color(30, 30, 30, 220)
local COLOR_BORDER = Color(10, 10, 10, 255)
local COLOR_TEXT = Color(255, 255, 255, 255)
local COLOR_ACCENT = Color(137, 154, 224, 255)

function AddNotification(text, type)
    table.insert(active_notifications, {
        text = text,
        start_time = Globals.GetCurrentTime(),
        accent_color = COLOR_ACCENT
    })
end

function DrawNotifications()
    if #active_notifications == 0 then return end

    local screen = Renderer.GetScreenSize()
    local notifications_to_keep = {}
    local y_offset = 20

    for i, msg in ipairs(active_notifications) do
        local time_elapsed = Globals.GetCurrentTime() - msg.start_time
        
        if time_elapsed < NOTIFICATION_DURATION then
            local alpha_multiplier = 1.0
            if time_elapsed > (NOTIFICATION_DURATION - FADE_OUT_TIME) then
                alpha_multiplier = (NOTIFICATION_DURATION - time_elapsed) / FADE_OUT_TIME
            end

            local text_width = ApproxTextWidth(msg.text)
            local box_width = text_width + 30
            local box_height = NOTIFICATION_FONT_HEIGHT + 12
            local x_pos = screen.x - box_width - 20
            
            local border_color = Color(COLOR_BORDER.r, COLOR_BORDER.g, COLOR_BORDER.b, COLOR_BORDER.a * alpha_multiplier)
            Renderer.DrawRectFilled(Vector2D(x_pos - 1, y_offset - 1), Vector2D(x_pos + box_width + 1, y_offset + box_height + 1), border_color, 0)
            
            local bg_color = Color(COLOR_BG.r, COLOR_BG.g, COLOR_BG.b, COLOR_BG.a * alpha_multiplier)
            Renderer.DrawRectFilled(Vector2D(x_pos, y_offset), Vector2D(x_pos + box_width, y_offset + box_height), bg_color, 0)
            
            local accent_color = Color(msg.accent_color.r, msg.accent_color.g, msg.accent_color.b, msg.accent_color.a * alpha_multiplier)
            Renderer.DrawRectFilled(Vector2D(x_pos, y_offset), Vector2D(x_pos + box_width, y_offset + 2), accent_color, 0)
            
            local text_color = Color(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, COLOR_TEXT.a * alpha_multiplier)
            Renderer.DrawText(NOTIFICATION_FONT, msg.text, Vector2D(x_pos + 15, y_offset + 6), false, true, text_color)
            
            y_offset = y_offset + box_height + 10
            table.insert(notifications_to_keep, msg)
        end
    end
    active_notifications = notifications_to_keep
end

local CURRENT_VERSION = get_self_version()
local last_update_check = 0
local notified_about_availability = false
local notified_about_completion = false
local previous_auto_update_state = false

local function checkForUpdate()
    if notified_about_completion then return end
    print("Checking for script updates...")
    
    local cache_buster = "?cb=" .. Globals.GetTickCount()
    local remote_script_content = http_get(SCRIPT_URL .. cache_buster)
    
    if not remote_script_content or #remote_script_content == 0 then
        print("Update check failed: Could not fetch remote script file.")
        return
    end
    
    local latest_version = remote_script_content:match("%-%-%s*@version%s*:%s*([%d%.]+)") or "0.0"
    print("Current: v" .. CURRENT_VERSION .. ", Latest: v" .. latest_version)

    if latest_version ~= "0.0" and latest_version ~= CURRENT_VERSION then
        if not notified_about_availability then
            AddNotification("New version available: v" .. latest_version, "available")
            notified_about_availability = true
        end
        
        if menu_auto_update_enabled:GetBool() then
            print("Auto-update enabled. Overwriting script...")
            if write_file(SCRIPT_PATH, remote_script_content) then
                print("Update successful! File overwritten. Please reload scripts.")
                if not notified_about_completion then
                    AddNotification("Update successful! Please reload scripts.", "complete")
                    notified_about_completion = true
                end
            else
                print("Update failed: Could not write to script file.")
            end
        end
    else
        print("Your script is up to date.")
    end
    last_update_check = Globals.GetCurrentTime()
end

local function onRender()
    local current_time = Globals.GetCurrentTime()
    local current_auto_update_state = menu_auto_update_enabled:GetBool()

    if Globals.IsConnected() and (current_time - last_update_check > UPDATE_INTERVAL) then
        checkForUpdate()
    end

    if notified_about_availability and not notified_about_completion and current_auto_update_state and not previous_auto_update_state then
        print("Checkbox enabled, starting update process immediately.")
        checkForUpdate()
    end

    previous_auto_update_state = current_auto_update_state
    
    DrawNotifications()
end

Cheat.RegisterCallback("OnRenderer", onRender)

local initial_check_thread = coroutine.create(checkForUpdate)
coroutine.resume(initial_check_thread)

print("Script Auto-Updater Loaded. Current version: " .. CURRENT_VERSION)
