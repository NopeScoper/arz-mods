script_name("ARZCatcher Remake")
script_author("Fern_Sennheiser")
script_version("2.1") -- Немного обновил версию

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
local font = renderCreateFont("Arial", 8, 5)

-- Конфиг по умолчанию
local cfg_name = "ARZCatcher_settings.ini"
local default_cfg = {
    settings = {
        activation_key = 0, -- Код клавиши (0 = не назначена)
        flood_delay = 100,  -- Задержка в мс
        key_name = "Нет"    -- Название клавиши для отображения
    }
}

-- Загрузка или создание конфига
local config = inicfg.load(default_cfg, cfg_name)
if not config then
    inicfg.save(default_cfg, cfg_name)
    config = default_cfg
end

-- Переменные для биндера
local is_binding = false

-- Настройка стиля ImGui (опционально)
function apply_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    style.WindowRounding = 5.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.1, 0.1, 0.1, 0.9)
    colors[imgui.Col.TitleBg] = imgui.ImVec4(1.0, 0.5, 0.0, 0.8)
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(1.0, 0.5, 0.0, 1.0)
    colors[imgui.Col.Button] = imgui.ImVec4(1.0, 0.5, 0.0, 0.6)
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(1.0, 0.5, 0.0, 0.8)
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(1.0, 0.5, 0.0, 1.0)
end
apply_style()

function main()
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage("{FF0000}[AC]{FFFFFF} Скрипт запущен! Введите {ffb400}/acz {FFFFFF}для настроек.", -1)
    
    -- Команда для открытия меню
    sampRegisterChatCommand('acz', function()
        main_window_state.v = not main_window_state.v
    end)

    while true do
        wait(0)
        
        -- Логика ImGui (скрытие курсора)
        imgui.Process = main_window_state.v
        
        -- Обработка клавиши активации
        if config.settings.activation_key ~= 0 and not is_binding and not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() then
            if wasKeyPressed(config.settings.activation_key) then
                status = not status
                if status then
                    sampAddChatMessage("{FF0000}[AC]{FFFFFF} Ловля активирована! Флужу Alt (In-Game)...", -1)
                else
                    sampAddChatMessage("{FF0000}[AC]{FFFFFF} Ловля выключена.", -1)
                end
            end
        end

        -- Логика флуда Альтом
        if status then
            -- ИСПОЛЬЗУЕМ setGameKeyState ВМЕСТО setVirtualKeyDown
            -- 21 - это ID игрового действия "Walk" (по умолчанию Alt)
            setGameKeyState(21, 255) 
            wait(50) -- Небольшая задержка удержания
            setGameKeyState(21, 0)
            
            -- Задержка из настроек
            wait(config.settings.flood_delay) 
        end
    end
end

function imgui.OnDrawFrame()
    if main_window_state.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(350, 200), imgui.Cond.FirstUseEver)
        
        imgui.Begin(u8"Настройки ARZCatcher", main_window_state)
        
        imgui.Text(u8"Статус работы: ")
        imgui.SameLine()
        if status then
            imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), u8"АКТИВЕН")
        else
            imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), u8"ВЫКЛЮЧЕН")
        end
        
        imgui.Separator()
        
        -- Настройка клавиши
        imgui.Text(u8"Клавиша активации:")
        local btn_text = is_binding and u8"Нажмите клавишу..." or u8(config.settings.key_name)
        if imgui.Button(btn_text .. "##bind", imgui.ImVec2(150, 25)) then
            is_binding = true
            lua_thread.create(function()
                while is_binding do 
                    wait(0)
                    -- Перебор клавиш для бинда
                    for i = 1, 255 do
                        if wasKeyPressed(i) then
                            -- Исключаем ЛКМ(1) и некоторые системные
                            if i ~= 1 and i ~= 2 then 
                                config.settings.activation_key = i
                                config.settings.key_name = vkeys.id_to_name(i)
                                inicfg.save(config, cfg_name)
                                is_binding = false
                                break
                            end
                        end
                    end
                end
            end)
        end
        if config.settings.activation_key ~= 0 then
            imgui.SameLine()
            if imgui.Button(u8"Сброс", imgui.ImVec2(50, 25)) then
                config.settings.activation_key = 0
                config.settings.key_name = "Нет"
                inicfg.save(config, cfg_name)
            end
        end

        imgui.Separator()

        -- Настройка задержки
        imgui.Text(u8"Задержка флуда Alt (мс):")
        local delay_ptr = imgui.ImInt(config.settings.flood_delay)
        if imgui.SliderInt("##delay", delay_ptr, 10, 1000) then
            config.settings.flood_delay = delay_ptr.v
            inicfg.save(config, cfg_name)
        end
        
        imgui.Separator()
        imgui.TextDisabled(u8"Автор мода: Fern_Sennheiser (баньте его )")
        -- Я Fern_Sennheiser признаю что создал этот скрипт чтобы не честно ловить лавки на аризоне в рестарт, не баньте меня пожалуйста :)
        imgui.End()
    end
end

-- Обработка диалога (покупка)
function events.onShowDialog(dialogId, style, title, button1, button2, text)
    if status and dialogId == 3010 then
        sampSendDialogResponse(dialogId, 1, 0, 0)
        -- sampAddChatMessage("{FF0000}[AC]{FFFFFF} Попытка покупки лавки...", -1)
        -- Не выключаем здесь, ждем подтверждения в чате
        return false -- Скрываем диалог (опционально, если хотите видеть - уберите эту строку)
    end
end

-- Обработка сообщений в чате (Авто-стоп)
function events.onServerMessage(color, text)
    -- Очищаем текст от цветовых кодов для точного поиска
    local clean_text = text:gsub("{......}", "")
    
    -- Ищем нужное сообщение
    -- [Подсказка] Вы успешно арендовали лавку для продажи/покупки товара!
    if clean_text:find("Вы успешно арендовали лавку") then
        if status then
            status = false
            sampAddChatMessage("{FF0000}[AC]{FFFFFF} Лавка поймана! Скрипт {FF0000}выключен автоматически{FFFFFF}.", -1)
        end
    end
end