script_name("Fern_Sennheiser")
script_author("Fern_Sennheiser")
script_version("1.4.8.8") -- Чуть обновил версию для порядка

require "lib.moonloader"
local events = require "samp.events"
local imgui = require "imgui"
local vkeys = require "vkeys"
local inicfg = require "inicfg"
local encoding = require "encoding"
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Основные переменные
local main_window_state = imgui.ImBool(false)
local status = false

-- Конфиг по умолчанию
local cfg_name = "Fern_settings.ini"
local default_cfg = {
    settings = {
        activation_key = 0,
        flood_delay = 100,
        key_name = "Нет",
        send_phrase = false,
        catch_phrase = "мяу",
        chat_delay_sec = 0.5 -- По умолчанию 0.5 секунды
    }
}

-- Загрузка конфига
local config = inicfg.load(default_cfg, cfg_name)
if not config then
    inicfg.save(default_cfg, cfg_name)
    config = default_cfg
end

-- Если обновились со старой версии и нет настройки секунд
if config.settings.chat_delay_sec == nil then
    config.settings.chat_delay_sec = 0.5
    inicfg.save(config, cfg_name)
end

-- Буфер для текстового поля
local phrase_buffer = imgui.ImBuffer(u8(config.settings.catch_phrase), 256)
local is_binding = false

-- === СТИЛЬ ИНТЕРФЕЙСА ===
function apply_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    
    style.WindowPadding = imgui.ImVec2(10, 10)
    style.FramePadding = imgui.ImVec2(8, 6)
    style.ItemSpacing = imgui.ImVec2(8, 6)
    style.ScrollbarSize = 12.0
    style.ScrollbarRounding = 9.0
    style.GrabMinSize = 5.0
    style.WindowRounding = 8.0 
    style.FrameRounding = 4.0
    style.ChildWindowRounding = 6.0 
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    
    colors[imgui.Col.Text]                  = imgui.ImVec4(0.95, 0.96, 0.98, 1.00)
    colors[imgui.Col.TextDisabled]          = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[imgui.Col.WindowBg]              = imgui.ImVec4(0.10, 0.10, 0.10, 1.00) 
    colors[imgui.Col.ChildWindowBg]         = imgui.ImVec4(0.13, 0.13, 0.13, 1.00) 
    colors[imgui.Col.PopupBg]               = imgui.ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[imgui.Col.Border]                = imgui.ImVec4(0.25, 0.25, 0.25, 0.50)
    colors[imgui.Col.BorderShadow]          = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[imgui.Col.FrameBg]               = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[imgui.Col.FrameBgHovered]        = imgui.ImVec4(0.26, 0.26, 0.26, 1.00)
    colors[imgui.Col.FrameBgActive]         = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    colors[imgui.Col.TitleBg]               = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[imgui.Col.TitleBgActive]         = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[imgui.Col.TitleBgCollapsed]      = imgui.ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[imgui.Col.CheckMark]             = imgui.ImVec4(0.80, 0.80, 0.80, 1.00)
    colors[imgui.Col.SliderGrab]            = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[imgui.Col.SliderGrabActive]      = imgui.ImVec4(0.70, 0.70, 0.70, 1.00)
    colors[imgui.Col.Button]                = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[imgui.Col.ButtonHovered]         = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
    colors[imgui.Col.ButtonActive]          = imgui.ImVec4(0.35, 0.35, 0.35, 1.00)
    colors[imgui.Col.Header]                = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[imgui.Col.HeaderHovered]         = imgui.ImVec4(0.26, 0.26, 0.26, 1.00)
    colors[imgui.Col.HeaderActive]          = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    colors[imgui.Col.ResizeGrip]            = imgui.ImVec4(0.26, 0.59, 0.98, 0.25)
    
    if imgui.Col.Separator then
        colors[imgui.Col.Separator] = imgui.ImVec4(0.43, 0.43, 0.50, 0.50)
    end
end
apply_style()

function main()
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{FF0000}[Fern]{FFFFFF} Скрипт запущен! Автор: {ffb400}Fern_Sennheiser", -1)
    sampAddChatMessage("{FF0000}[Fern]{FFFFFF} Введите {ffb400}/fern {FFFFFF}для настроек.", -1)
    
    sampRegisterChatCommand('fern', function()
        main_window_state.v = not main_window_state.v
    end)

    while true do
        wait(0)
        imgui.Process = main_window_state.v
        
        -- [ИЗМЕНЕНИЕ] Закрытие на ESC (0x1B)
        if main_window_state.v and wasKeyPressed(0x1B) and not is_binding then
            main_window_state.v = false
        end
        
        if config.settings.activation_key ~= 0 and not is_binding and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
            if wasKeyPressed(config.settings.activation_key) then
                status = not status
                if status then
                    sampAddChatMessage("{808080}[Fern]{FFFFFF} Ловля: {00FF00}Fern ловит!", -1)
                else
                    sampAddChatMessage("{808080}[Fern]{FFFFFF} Ловля: {FF0000}Fern не ловит!", -1)
                end
            end
        end

        if status then
            setGameKeyState(21, 255) 
            wait(50)
            setGameKeyState(21, 0)
            wait(config.settings.flood_delay) 
        end
    end
end

function imgui.OnDrawFrame()
    if main_window_state.v then
        local sw, sh = getScreenResolution()
        
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(380, 460), imgui.Cond.FirstUseEver)
        
        imgui.Begin(u8"Fern_Sennheiser", main_window_state, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
        
        imgui.BeginGroup()
            imgui.Text(u8"Текущий статус:")
            imgui.SameLine()
            if status then
                imgui.TextColored(imgui.ImVec4(0.4, 1.0, 0.4, 1.0), u8"Fern ловит")
            else
                imgui.TextColored(imgui.ImVec4(1.0, 0.4, 0.4, 1.0), u8"Fern не ловит")
            end
        imgui.EndGroup()
        
        imgui.Spacing()
        
        imgui.BeginChild("##SettingsPanel", imgui.ImVec2(0, 320), true)
            
            -- 1. Бинд клавиши
            imgui.TextDisabled(u8"Кнопка на которую ловит Fern")
            local btn_text = is_binding and u8"Fern жмет!" or u8(config.settings.key_name)
            if imgui.Button(btn_text .. "##bind", imgui.ImVec2(180, 25)) then
                is_binding = true
                lua_thread.create(function()
                    while is_binding do 
                        wait(0)
                        for i = 1, 255 do
                            if wasKeyPressed(i) and i ~= 1 and i ~= 2 then 
                                config.settings.activation_key = i
                                config.settings.key_name = vkeys.id_to_name(i)
                                inicfg.save(config, cfg_name)
                                is_binding = false
                                break
                            end
                        end
                    end
                end)
            end
            
            if config.settings.activation_key ~= 0 then
                imgui.SameLine()
                if imgui.Button(u8"Fern сбрасывает", imgui.ImVec2(110, 25)) then
                    config.settings.activation_key = 0
                    config.settings.key_name = "Нет"
                    inicfg.save(config, cfg_name)
                end
            end
            
            imgui.Spacing()
            
            -- 2. Слайдер задержки флуда (Alt)
            imgui.TextDisabled(u8"Fern ждет (MC) [Флуд Alt]")
            imgui.PushItemWidth(250)
            local delay_ptr = imgui.ImInt(config.settings.flood_delay)
            if imgui.SliderInt("##delay", delay_ptr, 10, 1000) then
                config.settings.flood_delay = delay_ptr.v
                inicfg.save(config, cfg_name)
            end
            imgui.PopItemWidth()

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()

            -- 3. Настройка кричалки
            local chat_check = imgui.ImBool(config.settings.send_phrase)
            if imgui.Checkbox(u8"Fern пишет в чат:", chat_check) then
                config.settings.send_phrase = chat_check.v
                inicfg.save(config, cfg_name)
            end

            if config.settings.send_phrase then
                imgui.Spacing()
                
                -- Текст фразы
                imgui.TextDisabled(u8"Текст фразы:")
                imgui.PushItemWidth(250)
                if imgui.InputText("##phrase", phrase_buffer) then
                    config.settings.catch_phrase = u8:decode(phrase_buffer.v)
                    inicfg.save(config, cfg_name)
                end
                imgui.PopItemWidth()
                
                imgui.Spacing()
                
                -- [ИЗМЕНЕНИЕ] Увеличен размер поля (с 100 до 250)
                imgui.TextDisabled(u8"Задержка отправки (сек):")
                imgui.PushItemWidth(250) 
                
                local sec_ptr = imgui.ImFloat(config.settings.chat_delay_sec)
                -- "%.2f" означает 2 знака после запятой, например 1.50
                if imgui.InputFloat("##sec_delay", sec_ptr, 0.1, 1.0, "%.2f") then
                    if sec_ptr.v < 0 then sec_ptr.v = 0 end -- Не даем ввести меньше 0
                    config.settings.chat_delay_sec = sec_ptr.v
                    inicfg.save(config, cfg_name)
                end
                imgui.PopItemWidth()
                -- Перенес подсказку под поле, так как поле стало широким
                imgui.TextColored(imgui.ImVec4(1, 1, 1, 0.6), u8"(Пример: 0.5 или 2.0)")
            end
            
        imgui.EndChild()
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        imgui.TextDisabled(u8"Читер: Fern_Sennheiser | Ver: 1.4.8.8")
        
        imgui.End()
    end
end

function events.onShowDialog(dialogId, style, title, button1, button2, text)
    if status and dialogId == 3010 then
        sampSendDialogResponse(dialogId, 1, 0, 0)
        return false 
    end
end

function events.onServerMessage(color, text)
    local clean_text = text:gsub("{......}", "")
    if clean_text:find("Вы успешно арендовали лавку") then
        if status then
            status = false
            sampAddChatMessage("{808080}[Fern]{FFFFFF} АХУЕТЬ! Ты словил, что за лев этот тигр!.", -1)
            
            if config.settings.send_phrase then
                lua_thread.create(function()
                    -- Переводим секунды из конфига в миллисекунды
                    local wait_ms = math.floor(config.settings.chat_delay_sec * 1000)
                    wait(wait_ms)
                    sampSendChat(config.settings.catch_phrase)
                end)
            end
        end
    end
end