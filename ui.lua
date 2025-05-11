local ffi = require("ffi")

local ui = {
    _tick=0,
    _mouse_down_tick=0,
    default_font = love.graphics.newFont(14, "mono"),
    types = {
        BUTTON = 1,
        SLIDER = 2,
        TEXT = 3,
        ButtonType = {
            STATIC = 1,
            INPUT = 2
        }
    },
    shaders={
        vertical_gradient=love.graphics.newShader([[
            extern vec4 colorA;
            extern vec4 colorB;
            extern vec2 rectPos;
            extern vec2 rectSize;
            vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
                float gradient = (screen_coords.y - rectPos.y) / rectSize.y;
                gradient = clamp(gradient, 0.0, 1.0);
                return mix(colorA, colorB, gradient);
            }
        ]]),
        horizontal_gradient=love.graphics.newShader([[
            extern vec4 colorA;
            extern vec4 colorB;
            extern vec2 rectPos;
            extern vec2 rectSize;
            vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
                float gradient = (screen_coords.x - rectPos.x) / rectSize.x;
                gradient = clamp(gradient, 0.0, 1.0);
                return mix(colorA, colorB, gradient);
            }
        ]])
    },
    draw_shader={}
}

ui.default_font:setFilter("nearest", "nearest")

ffi.cdef[[
    short GetKeyState(int nVirtKey);
]]

local function isCapsLockActive()
    local state = ffi.C.GetKeyState(0x14)
    return (state % 2) ~= 0
end

local function default(value, default_value)
    if value then
        return value
    else
        return default_value
    end
end

local function contains(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

local function index(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then return k end
    end
    return nil
end

local function round(number, snap)
    return math.floor((number + snap / 2) / snap) * snap
end

function ui.draw_shader.vgradientRect(x, y, width, height, colorA, colorB)
    local corA = {love.math.colorFromBytes(colorA)}
    local corB = {love.math.colorFromBytes(colorB)}
    if corA[4] == nil then corA[4] = 1 end
    if corB[4] == nil then corB[4] = 1 end
	love.graphics.reset()
    ui.shaders.vertical_gradient:send("colorA", corA)
    ui.shaders.vertical_gradient:send("colorB", corB)
    ui.shaders.vertical_gradient:send("rectPos", {x, y})
    ui.shaders.vertical_gradient:send("rectSize", {width, height})
    love.graphics.setShader(ui.shaders.vertical_gradient)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setShader()
end

function ui.draw_shader.hgradientRect(x, y, width, height, colorA, colorB)
    local corA = {love.math.colorFromBytes(colorA)}
    local corB = {love.math.colorFromBytes(colorB)}
    if corA[4] == nil then corA[4] = 1 end
    if corB[4] == nil then corB[4] = 1 end
	love.graphics.reset()
    ui.shaders.horizontal_gradient:send("colorA", corA)
    ui.shaders.horizontal_gradient:send("colorB", corB)
    ui.shaders.horizontal_gradient:send("rectPos", {x, y})
    ui.shaders.horizontal_gradient:send("rectSize", {width, height})
    love.graphics.setShader(ui.shaders.horizontal_gradient)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setShader()
end

ui.keyboard = {}

ui.keyboard._keys = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', "'", ',', '-', '.', '/', ';', '=', '[', '\\', ']', '`', "space", "backspace", "delete", "lshift", "rshift", "home", "end", "left", "right", "up", "down", "lctrl", "rctrl"}

ui.keyboard._pressable_keys = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', "'", ',', '-', '.', '/', ';', '=', '[', '\\', ']', '`', "space"}
ui.keyboard._pressable_shift_keys = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', ')', '!', '@', '#', '$', '%', '¨', '&', '*', '(', "\"", '<', '_', '>', '?', ':', '+', '{', '|', '}', '\'', "space"}

ui.keyboard.keys = {}

for _, key in ipairs(ui.keyboard._keys) do
    ui.keyboard.keys[key] = -1
end

function ui.keyboard.translate(key, shift_pressed)
    if not contains(ui.keyboard._pressable_keys, key) then
        return ""
    end
    if key == "space" then return " " end
    if shift_pressed then
        if index(ui.keyboard._pressable_keys, key) then
            return ui.keyboard._pressable_shift_keys[index(ui.keyboard._pressable_keys, key)]
        else
            return key
        end
    else
        return key
    end
end

local function keysPressedTick()
    for key, value in pairs(ui.keyboard.keys) do
        if love.keyboard.isDown(key) then
            ui.keyboard.keys[key] = ui.keyboard.keys[key] + 1
        else
            ui.keyboard.keys[key] = 0
        end
    end
end

local function gen_circle(radius) -- chatgpt ahh function but idfc - Danidanijr
    local pixels = {}
    for y = -radius, radius do
        for x = -radius, radius do
            if x*x + y*y <= radius*radius then
                table.insert(pixels, {x, y})
            end
        end
    end
    return pixels
end

--[[`ui.new_Button(tbl)`

### Values
- hide: (boolean) = Whether or not to show the object. (default value = `false`)
- button_type: (number) = Type of the button. (default value = `ui.types.ButtonType.STATIC`)
- x: (number) = X Position
- y: (number) = Y Position
- w: (number) = Width. (default value = `100`)
- h: (number) = Height. (default value = `25`)
- show_text: (boolean) = whether or not to show the text in the button. (default value = `true`)
- text_align: (text) = Text aligning, left/center/right. (default value = `center`)
- text: (text) = Text inside of the button
- font: (love.graphics.newFont) = The font to use. (default value = `ui.default_font`)
- text_color: (table) = RGBA button text's color. (default value = `{255, 255, 255}`)
- text_scale: (number) = text scale. (default value = `1`)
- *text_shadow: (table)
    - *text_shadow.offset: (table) = offset of the shadow
        - text_shadow.offset.x: (number) = shadow's x offset. (default value = `2`)
        - text_shadow.offset.y: (number) = shadow's y offset. (default value = `2`)
    - text_shadow.color: (table) = color of the shadow. (default value = `{0, 0, 0, 127}`)
- *text_outline: (table)
    - text_outline.size: (number) = size of the outline. (default value = `1`)
    - text_outline.color: (table) = color of the outline. (default value = `{0, 0, 0}`)
- fill_type: (text) = Button Corner Fill Type. (default value = `line`)
- corner_radius: (number) = Button Corner Radius. (default value = `0`)
- border_radius: (number) = Button Border Radius. (default value = `2`)
- border_color: (table) = RGBA button border's color. (default value = `{255, 255, 255}`)
- border_hover_color: (table) = RGBA button border mouse hover's color. (default value = `{0, 255, 255}`)
- button_color: (table) = RGBA button's color. (default value = `{100,100,100}`)
- button_hover_color: (table) = RGBA button hover's color. (default value = `{0,100,100}`)
- on_before_tick(obj): (function) = Function that gets executed before on_hover, on_hold & on_click.
- on_hover(obj): (function) = Function that executes when you hover on the button.
- on_hold(obj): (function) = Function that executes when you hold down on the button with your mouse.
- on_click(obj): (function) = Function that executes when you click on the button.
- [INPUT TEXT MODE ONLY] on_text_change(obj): (function) = Function that executes when you change the text.
- on_after_tick(obj): (function) = Function that gets executed after on_hover, on_hold & on_click.
### Values (INPUT TEXT MODE)
- *cursor: (table)
    - cursor.show: (boolean) = whether to show the cursor input index rectangle thingy(?) or not. (default value = `true`)
    - cursor.color: (table) = RGBA cursor's color. (default value = `{255, 255, 255, 127}`)
    - cursor.blink: (boolean) = whether or not make the cursor blink. (default value = `true`)
]]
function ui.new_Button(tbl)
    tbl._type = ui.types.BUTTON
    tbl._creation_tick = ui._tick
    tbl._hold_tick = 0
    tbl._holding_in = false
    if tbl.button_type == ui.types.ButtonType.INPUT then
        tbl._cursor_index = #tbl.text
        tbl._cursor_last_typed = 0
    end
    return tbl
end

--[[`ui.new_Slider(tbl)`

### Values
- hide: (boolean) = Whether or not to show the object. (default value = `false`)
- x: (number) = X Position
- y: (number) = Y Position
- w: (number) = Width. (default value = `200`)
- sw: (number) = Slider Box's Width. (default value = `(h)`)
- h: (number) = Height. (default value = `25`)
- min: (number) = Minimum Value. (default value = `0`)
- max: (number) = Maximum Value. (default value = `100`)
- value: (number) = Value of the slider. (default value = `50`)

- *snap: (table)
    - interval: (number) = Interval of the value snap. (default value = `10`)

- fill_type: (text) = Slider Corner Fill Type. (default value = `line`)
- corner_radius: (number) = Slider Corner Radius. (default value = `0`)
- border_radius: (number) = Slider Border Radius. (default value = `2`)

- background_color: (table) = RGBA background's color. (default value = `{100,100,100}`)
- border_color: (table) = RGBA slider's background border's color. (default value = `{255, 255, 255}`)

- slider_color: (table) = RGBA slider's color. (default value = `{150,150,150}`)
- slider_hover_color: (table) = RGBA slider hover's color. (default value = `{0,150,150}`)
- slider_border_color: (table) = RGBA slider's color. (default value = `{255,255,255}`)
- slider_border_hover_color: (table) = RGBA slider border mouse hover's color. (default value = `{0, 255, 255}`)

- slider_drag_smoothness: (number) = Animation smoothness of the slider when you drag it around. (default value = `4`)

- on_before_tick(obj): (function) = Function that gets executed before on_hover, on_hold & on_click.
- on_hover(obj): (function) = Function that executes when you hover on the button.
- on_hold(obj): (function) = Function that executes when you hold down on the button with your mouse.
- on_click(obj): (function) = Function that executes when you click on the button.
- on_after_tick(obj): (function) = Function that gets executed after on_hover, on_hold & on_click.
]]--
function ui.new_Slider(tbl)
    tbl._type = ui.types.SLIDER
    tbl._creation_tick = ui._tick
    tbl._hold_tick = 0
    return tbl
end

--[[`ui.new_Text(tbl)`

### Values
- hide: (boolean) = Whether or not to show the object. (default value = `false`)
- x: (number) = X Position
- y: (number) = Y Position
- text_align: (text) = Text aligning, left/center/right. (default value = `left`)
- text_middle_align: (text) = Text's middle aligning, up/center/bottom. (default value = `up`)
- text: (text) = Text of course.
- font: (love.graphics.newFont) = The font to use. (default value = `ui.default_font`)
- text_color: (table) = Text's color. (default value = `{255, 255, 255}`)
- text_scale: (number) = text scale. (default value = `1`)
- *outline: (table)
    - outline.size: (number) = Size of the outline. (default value = `1`)
    - outline.color: (table) = Color of the outline. (default value = `{0, 0, 0}`)
- *shadow: (table)
    - *shadow.offset: (table) = offset of the shadow
        - shadow.offset.x: (number) = shadow's x offset. (default value = `2`)
        - shadow.offset.y: (number) = shadow's y offset. (default value = `2`)
    - shadow.color: (table) = color of the shadow. (default value = `{0, 0, 0, 127}`)
- on_tick: (function) = Function that gets executed every tick.
--]]
function ui.new_Text(tbl)
    tbl._type = ui.types.TEXT
    tbl._creation_tick = ui._tick
    return tbl
end

local function isValueIn(x, y, z) -- (x <= y) and (y <= z)
    return (x <= y) and (y <= z)
end

local function stretch_num(value, minn, maxx, new_min, new_max)
    return new_min + ((value - minn) / (maxx - minn)) * (new_max - new_min)
end

function ui.render(tbl)
    local mouseX, mouseY = love.mouse.getPosition()
    local mouse_down = love.mouse.isDown(1)
    for ind, obj in pairs(tbl) do
        if type(obj) == "table" then
            love.graphics.reset()

            if obj.hide == nil then
                obj.hide = false
            end

            if not obj.hide then
                if obj._type == ui.types.BUTTON then
                    local button_type = default(obj.button_type, ui.types.ButtonType.STATIC)
                    local text_align = default(obj.text_align, "center")
                    local changed_text = false
                    
                    if not obj.w then
                        obj.w = 100
                    end
                    if not obj.h then
                        obj.h = 25
                    end
                    if not obj.show_text then
                        obj.show_text = true
                    end

                    local is_hovering = false
                    
                    if isValueIn(obj.x, mouseX, obj.x + obj.w) and isValueIn(obj.y, mouseY, obj.y + obj.h) then
                        is_hovering = true
                    end

                    if not obj._hold_tick_tmp then
                        obj._hold_tick_tmp = 0
                    end
                    
                    if mouse_down then
                        obj._hold_tick_tmp = obj._hold_tick_tmp + 1
                    else
                        obj._hold_tick_tmp = 0
                    end

                    if obj._holding_in then
                        obj._hold_tick = obj._hold_tick + 1
                        if not mouse_down then
                            obj._holding_in = false
                            obj._hold_tick = 0
                        end
                    end

                    if is_hovering and obj._hold_tick_tmp == 1 then
                        obj._holding_in = true
                    end

                    if is_hovering and button_type == ui.types.ButtonType.INPUT then
                        local shift_pressed = false
                        local ctrl_pressed = false
                        if ui.keyboard.keys["lshift"] > 0 or ui.keyboard.keys["rshift"] > 0 then
                            shift_pressed = true
                        end
                        if isCapsLockActive() then
                            shift_pressed = not shift_pressed
                        end
                        if ui.keyboard.keys["lctrl"] > 0 or ui.keyboard.keys["rctrl"] > 0 then
                            ctrl_pressed = true
                        end
                        for k,v in pairs(ui.keyboard.keys) do
                            if v == 1 or v>=30 then
                                obj._cursor_last_typed = ui._tick
                                if k == "backspace" then
                                    changed_text = true
                                    obj._cursor_index = obj._cursor_index - 1
                                    if obj._cursor_index < 0 then
                                        obj._cursor_index = 0
                                    end
                                    obj.text = obj.text:sub(0, obj._cursor_index) .. obj.text:sub(obj._cursor_index+2, #obj.text)
                                elseif k == "delete" then
                                    changed_text = true
                                    obj.text = ""
                                    obj._cursor_index = 0
                                elseif k == "left" then
                                    obj._cursor_index = obj._cursor_index - 1
                                    if obj._cursor_index < 0 then
                                        obj._cursor_index = 0
                                    end
                                elseif k == "right" then
                                    obj._cursor_index = obj._cursor_index + 1
                                    if obj._cursor_index > #obj.text then
                                        obj._cursor_index = #obj.text
                                    end
                                elseif k == "end" then
                                    obj._cursor_index = #obj.text
                                elseif k == "home" then
                                    obj._cursor_index = 0
                                else
                                    if ctrl_pressed and k == "v" then
                                        changed_text = true
                                        obj.text = love.system.getClipboardText()
                                        obj.text = obj.text:gsub("\r\n", " "):gsub("\n", " ")
                                        obj._cursor_index = #obj.text
                                    else
                                        if #ui.keyboard.translate(k, shift_pressed) >= 1 then
                                            changed_text = true
                                            obj._cursor_index = obj._cursor_index + #ui.keyboard.translate(k, shift_pressed)
                                            obj.text = obj.text:sub(0, obj._cursor_index-1) .. ui.keyboard.translate(k, shift_pressed) .. obj.text:sub(obj._cursor_index, #obj.text)
                                        end
                                    end
                                end
                            end
                        end
                    end


                    love.graphics.setColor(love.math.colorFromBytes(default(obj.border_color, {255,255,255})))
                    love.graphics.setLineWidth(default(obj.border_radius, 2))
                    if is_hovering then
                        love.graphics.setColor(love.math.colorFromBytes(default(obj.border_hover_color, {0,255,255})))
                    end
                    love.graphics.rectangle(default(obj.fill_type, "line"), obj.x, obj.y, obj.w, obj.h, default(obj.corner_radius, 0))
                    
                    love.graphics.setColor(love.math.colorFromBytes(default(obj.button_color, {100,100,100})))
                    love.graphics.setLineWidth(0)
                    if is_hovering then
                        love.graphics.setColor(love.math.colorFromBytes(default(obj.button_hover_color, {0,100,100})))
                    end
                    love.graphics.rectangle(default(obj.fill_type, "fill"), obj.x, obj.y, obj.w, obj.h, default(obj.corner_radius, 0))
                    
                    local text_font = default(obj.font, ui.default_font)
                    local text_width = text_font:getWidth(obj.text)*default(obj.text_scale, 1)
                    local text_height = text_font:getHeight()*default(obj.text_scale, 1)

                    if obj.show_text then


                        local text_x, text_y = obj.x + (obj.w/2) - (text_width/2), obj.y + (obj.h/2) - (text_height/2)

                        if text_align == "left" then
                            text_x = obj.x
                        end
                        if text_align == "right" then
                            text_x = obj.x + obj.w - text_width
                        end
                        
                        if obj.text_shadow then
                            love.graphics.setColor(love.math.colorFromBytes(default(obj.text_shadow.color, {0,0,0,127})))

                            if not obj.text_shadow.offset then
                                obj.text_shadow.offset = {}
                            end

                            love.graphics.print(obj.text, text_font, text_x + default(obj.text_shadow.offset.x,2)*default(obj.text_scale, 1), text_y + default(obj.text_shadow.offset.y,2)*default(obj.text_scale, 1), 0, default(obj.text_scale, 1))
                        end

                        if obj.text_outline then
                            local points = gen_circle(default(obj.text_outline.size, 1))
            
                            love.graphics.setColor(love.math.colorFromBytes(default(obj.text_outline.color, {0,0,0})))
            
                            for k, v in ipairs(points) do
                                if not (v[1] == 0 and v[2] == 0) then
                                    love.graphics.print(obj.text, text_font, text_x+v[1]*default(obj.text_scale, 1), text_y+v[2]*default(obj.text_scale, 1), 0, default(obj.text_scale, 1))
                                end
                            end
                        end

                        love.graphics.setColor(love.math.colorFromBytes(default(obj.text_color, {255,255,255})))
                        love.graphics.print(obj.text, text_font, text_x, text_y, 0, default(obj.text_scale, 1))
                    end

                    if button_type == ui.types.ButtonType.INPUT then
                        if not obj.cursor then
                            obj.cursor = {}
                        end
                    end

                    if obj.cursor then
                        if default(obj.cursor.show, true) then
                            local show_cursor = false
                            if is_hovering then
                                if default(obj.cursor.blink, true) then
                                    show_cursor = (((obj._cursor_last_typed - ui._tick - 1) % 60) > 30)
                                end
                            else
                                show_cursor = false
                            end
                            if show_cursor then
                                local text_width_cursor = text_font:getWidth(obj.text:sub(0, obj._cursor_index))*default(obj.text_scale, 1)
                                local cursor_x = (obj.x + obj.w/2) + (text_width_cursor-text_width/2)
                                if text_align == "left" then
                                    cursor_x = obj.x + text_width_cursor
                                end
                                if text_align == "right" then
                                    cursor_x = (obj.x + obj.w) - (text_width-text_width_cursor)
                                end
                                love.graphics.setColor(love.math.colorFromBytes(default(obj.cursor.color, {255,255,255,127})))
                                love.graphics.rectangle("fill", cursor_x, obj.y+2, 1, obj.h-4)
                            end
                        end
                    end


                    if obj.on_before_tick then
                        obj.on_before_tick(obj)
                    end
                    if is_hovering then
                        if obj.on_hover then
                            obj.on_hover(obj)
                        end
                    end
                    if obj._holding_in then
                        if obj.on_hold then
                            obj.on_hold(obj)
                        end
                    end
                    if obj._hold_tick == 1 then
                        if obj.on_click then
                            obj.on_click(obj)
                        end
                    end
                    if changed_text then
                        if obj.on_text_change then
                            obj.on_text_change(obj)
                        end
                    end
                    if obj.on_after_tick then
                        obj.on_after_tick(obj)
                    end
                end

                if obj._type == ui.types.SLIDER then

                    if not obj.w then
                        obj.w = 200
                    end
                    if not obj.h then
                        obj.h = 25
                    end
                    if not obj.value then
                        obj.value = 50
                    end
                    if not obj.min then
                        obj.min = 0
                    end
                    if not obj.max then
                        obj.max = 100
                    end
                    if not obj._val_smooth then
                        obj._val_smooth = obj.value
                    end

                    if not obj.sw then
                        obj.sw = obj.h
                    end

                    local is_hovering = false

                    local slider_x_offset = stretch_num(obj._val_smooth, obj.min, obj.max, 0, obj.w - obj.sw)
                    
                    if isValueIn(obj.x+slider_x_offset, mouseX, obj.x + obj.sw+slider_x_offset) and isValueIn(obj.y, mouseY, obj.y + obj.h) then
                        is_hovering = true
                    end

                    if mouse_down then
                        obj._hold_tick_tmp = obj._hold_tick_tmp + 1
                    else
                        obj._hold_tick_tmp = 0
                    end

                    if obj._holding_in then
                        obj._hold_tick = obj._hold_tick + 1
                        if not mouse_down then
                            obj._holding_in = false
                            obj._hold_tick = 0
                        end
                    end

                    if is_hovering and obj._hold_tick_tmp == 1 then
                        obj._holding_in = true
                    end
            
                    if obj._holding_in then
                        local val = stretch_num(mouseX, obj.x + obj.sw/2, obj.x + obj.w - obj.sw/2, obj.min, obj.max)
                        if obj.snap then
                            val = round(val, default(obj.snap.interval, 10))
                        end
                        obj.value = math.min(math.max(val, obj.min), obj.max)
                    end

                    obj._val_smooth = obj._val_smooth + ((obj.value) - (obj._val_smooth)) / default(obj.slider_drag_smoothness, 4)

                    love.graphics.setColor(love.math.colorFromBytes(default(obj.border_color, {255,255,255})))
                    love.graphics.setLineWidth(default(obj.border_radius, 2))
                    love.graphics.rectangle(default(obj.fill_type, "line"), obj.x, obj.y, obj.w, obj.h, default(obj.corner_radius, 0))
                    
                    love.graphics.setColor(love.math.colorFromBytes(default(obj.background_color, {100,100,100})))
                    love.graphics.setLineWidth(0)
                    love.graphics.rectangle(default(obj.fill_type, "fill"), obj.x, obj.y, obj.w, obj.h, default(obj.corner_radius, 0))
                    

                    love.graphics.setColor(love.math.colorFromBytes(default(obj.slider_border_color, {255,255,255})))
                    love.graphics.setLineWidth(default(obj.border_radius, 2))
                    if is_hovering then
                        love.graphics.setColor(love.math.colorFromBytes(default(obj.slider_border_hover_color, {0,255,255})))
                    end
                    love.graphics.rectangle(default(obj.fill_type, "line"), obj.x+slider_x_offset, obj.y, obj.sw, obj.h, default(obj.corner_radius, 0))
                    
                    love.graphics.setColor(love.math.colorFromBytes(default(obj.slider_color, {150,150,150})))
                    love.graphics.setLineWidth(0)
                    if is_hovering then
                        love.graphics.setColor(love.math.colorFromBytes(default(obj.slider_hover_color, {0,150,150})))
                    end
                    love.graphics.rectangle(default(obj.fill_type, "fill"), obj.x+slider_x_offset, obj.y, obj.sw, obj.h, default(obj.corner_radius, 0))
                    
                    
                    
                    if obj.on_before_tick then
                        obj.on_before_tick(obj)
                    end
                    if is_hovering then
                        if obj.on_hover then
                            obj.on_hover(obj)
                        end
                    end
                    if obj._holding_in then
                        if obj.on_hold then
                            obj.on_hold(obj)
                        end
                    end
                    if obj._hold_tick == 1 then
                        if obj.on_click then
                            obj.on_click(obj)
                        end
                    end
                    if obj.on_after_tick then
                        obj.on_after_tick(obj)
                    end
                end

                if obj._type == ui.types.TEXT then
                    local text_align = default(obj.text_align, "left")
                    local text_mid_align = default(obj.text_middle_align, "up")
                    local text_font = default(obj.font, ui.default_font)

                    local text_width = text_font:getWidth(obj.text)*default(obj.text_scale, 1)
                    local text_height = text_font:getHeight()*default(obj.text_scale, 1)

                    local text_x, text_y = obj.x, obj.y

                    if text_align == "center" then
                        text_x = obj.x - (text_width/2)
                    end
                    if text_align == "right" then
                        text_x = obj.x - text_width
                    end

                    if text_mid_align == "center" then
                        text_y = obj.y - (text_height/2)
                    end
                    if text_mid_align == "bottom" then
                        text_y = obj.y - (text_height)
                    end

                    love.graphics.setColor(love.math.colorFromBytes(default(obj.text_color, {255,255,255})))

                    if obj.shadow then
                        love.graphics.setColor(love.math.colorFromBytes(default(obj.shadow.color, {0,0,0,127})))

                        if not obj.shadow.offset then
                            obj.shadow.offset = {}
                        end

                        love.graphics.print(obj.text, text_font, text_x + default(obj.shadow.offset.x,2)*default(obj.text_scale, 1), text_y + default(obj.shadow.offset.y,2)*default(obj.text_scale, 1), 0, default(obj.text_scale, 1))
                    end

                    if obj.outline then
                        local points = gen_circle(default(obj.outline.size, 1))

                        love.graphics.setColor(love.math.colorFromBytes(default(obj.outline.color, {0,0,0})))

                        for k, v in ipairs(points) do
                            if not (v[1] == 0 and v[2] == 0) then
                                love.graphics.print(obj.text, text_font, text_x+v[1]*default(obj.text_scale, 1), text_y+v[2]*default(obj.text_scale, 1), 0, default(obj.text_scale, 1))
                            end
                        end
                    end

                    
                    love.graphics.setColor(love.math.colorFromBytes(default(obj.text_color, {255,255,255})))
                    love.graphics.print(obj.text, text_font, text_x, text_y, 0, default(obj.text_scale, 1))
                    
                    if obj.on_tick then
                        obj.on_tick(obj)
                    end
                end
            end
        end
    end
end

function ui.tick()
    keysPressedTick()
    local mouse_down = love.mouse.isDown(1)
    if mouse_down then
        ui._mouse_down_tick = ui._mouse_down_tick + 1
    else
        ui._mouse_down_tick = 0
    end
    ui._tick = ui._tick + 1
end

return ui