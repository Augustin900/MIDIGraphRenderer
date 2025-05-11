--[[
hi congrats for seeing this source code by renaming .love to .zip or something.
also note this code is pretty bad lmao

- Danidanijr
]]--

ui = require("ui")
tick = require("tick")
json = require("json")

tick.framerate=60
tick.rate=1/60

program = {
    disable_bg = false,
    bg_gradient = {{128/2, 0, 64/2}, {0, 128/2, 128/2}},
    bg_render_gradient = {{0, 64, 64}, {64, 0, 64}},
    render=false,
    render_preview=false,
    finish_render=false,
    ffmpegProcess=nil,
    canvas=nil,
    time_since_render=0,
    ui={},
    render_ui={},
    text_input_style={
        button_hover_color={75,75,75},
        border_hover_color={255,255,0},
        on_click = function (obj)
            obj.text=""
            program.sounds.text_reset:play()
        end
    },
    csv={},
    font_paths = {
        ["default"] = "",
        ["Nokia Cellphone FC"] = "nokiafc22.ttf",
        ["Foldit"] = "Foldit-Bold.ttf",
        ["Retro Gaming"] = "RetroGaming1edit.ttf",
        ["Century Gothic"] = "GOTHICB.ttf",
        ["Century"] = "CENTURY.ttf",
        ["Calisto MT"] = "CALISTB.ttf",
        ["Futura"] = "FuturaMedium.ttf",
        ["Impact"] = "impact.ttf",
        ["Agency FB"] = "AGENCYB.ttf",
        ["Consolas"] = "consolab.ttf",
        ["Gotham Pro"] = "Gotham Pro Bold.ttf",
        ["Cocogoose"] = "Cocogoose_trial.otf",
        ["Daggersquare"] = "DAGGERSQUARE.otf",
        ["Hauser"] = "Hauser.otf",
        ["Pepsi"] = "PEPSI_pl.ttf"
    },
    fonts = {},
    VERSION="1.0_BETA",
    render_texts = {
        "I change every 10 seconds!",
        "Tip: You can use the Additive blending mode in your Video Editor on the exported video!",
        "Tip: Fish",
        "Brought to you by Danidanijr!",
        "Made with LÖVE2D!",
        "If there are any bugs, report it to Danidanijr on discord!",
        ":3",
        "Tip: Use Zenith 2 for exporting the midi's CSV frame note count data!",
        "Make sure to have ffmpeg.exe in the program's folder before rendering!",
        "Fun fact: I made this program because it's more easier to use! (AviUtl scripting way is a bit harder)",
        "Tip: You can hold left / right arrow keys on preview mode to navigate through the time! And hold shift to go faster! (also hold down to pause the time)",
        "Tip: Hover over an text box to input text there, Click on it to reset the text and press ctrl + v to paste text on it!",
        "Tip: Transparent hex colors are also supported! Example: '#FF7F007F'",
        "Fun fact: The entire (main.lua) code has over 1.5k lines!",
        "Tip: You can use your mouse to navigate through the time on the top bar!",
        "Yeah i know the line graph looks kinda sharp, that's how 'love.graphics.line()' works. :P"
    }
}

function getFont(name, size)
    if name == "default" then return love.graphics.newFont(size) end
    return love.graphics.newFont(program.font_paths[name], size)
end

for k, v in pairs(program.font_paths) do
    program.fonts[k] = getFont(k, 24)
end

program.small_font = love.graphics.newFont(11, "mono")
--program.small_font:setFilter("nearest", "nearest")

program.sounds = {
    done = love.audio.newSource(
        love.sound.newSoundData("render_done.wav")
    ),
    button = love.audio.newSource(
        love.sound.newSoundData("button_click.wav")
    ),
    text_reset = love.audio.newSource(
        love.sound.newSoundData("text_reset.wav")
    ),
    error = love.audio.newSource(
        love.sound.newSoundData("error.wav")
    )
}

program.images = {
    danidanijr = love.graphics.newImage("danidanijr.png")
}

function playButton()
    program.sounds.button:play()
end

render_vars = {
    tick=0
}

input_vars = {
    csv_fps = 60,
    width=640,
    height=360,
    fps=60,
    font="Foldit",
    font_size=24,
    bg_color="#000000",
    line_color="#00FFFF",
    text_color="#FFFFFF7F",
    hbar_color="#FFFFFF7F",
    split_char=",",
    split_index=1,
    abbreviate_number=false,
    show_text=true,
    show_bars=true,
    use_transparency_mask=false,
    abbreviate_digits=3,
    zoom_smoothness=8,
    graph_duration=2.0,
    text_milestone_scale_mul=1.5,
    padding_mul=0.1,
    graph_smoothness=0,
    line_thickness=3,
    hbar_thickness=1,
    text_x_offset=2,
    text_y_offset=2,
    output_path="output.mp4",
    ffmpeg_command="ffmpeg -y -framerate {{fps}} -f rawvideo -s {{canvas_width}}x{{canvas_height}} -pix_fmt rgba -i - \"{{output_path}}\""
} -- stuff like csv_fps, etc idk

canvas_vars = {} -- stuff like _cam_min_zoom, etc idk

WIDTH = 1280
HEIGHT = 720

function parseNumText(input, default)
    local number = tonumber(input)
    if number == nil then
        return default
    else
        return number
    end
end

function pixelFunction(x, y, r, g, b, a)
    if math.floor(r*255) == 10 then
        r = 9
    end
    if math.floor(g*255) == 10 then
        g = 9
    end
    if math.floor(b*255) == 10 then
        b = 9
    end
    return r,g,b,1
end

function renderFrameToFFMPEG_Process()
    local imageData = program.canvas:newImageData()
    program.ffmpegProcess:write(imageData:getString())
    program.ffmpegProcess:flush()
end

function setColor(tbl)
    if input_vars.use_transparency_mask then
        love.graphics.setColor({1, 1, 1, tbl[4] or 1})
    else
        love.graphics.setColor(tbl)
    end
end

function getCsvTable_Tick(tick, length) -- returns like {str,str,str,str, ...}
    local output = {}
    for t = 1, length do
        local ind = (t + tick) - length
        local item = program.csv[ind]
        if item then
            table.insert(output, item)
        else
            table.insert(output, program.csv[1])
        end
    end
    return output
end

function splitBy(text, splitchr)
	local result = {}
	for substring in string.gmatch(text, '([^' .. splitchr .. ']+)') do
		table.insert(result, substring)
	end
	return result
end

function stretch_num(value, minn, maxx, new_min, new_max)
    return new_min + ((value - minn) / (maxx - minn)) * (new_max - new_min)
end

function abbreviate(num, decimal_places)
	local a = ""
	if math.abs(num) >= 1000 then
		a = "K"
		num = num / 1000
	end
	if math.abs(num) >= 1000 then
		a = "M"
		num = num / 1000
	end
	if math.abs(num) >= 1000 then
		a = "B"
		num = num / 1000
	end
	if math.abs(num) >= 1000 then
		a = "T"
		num = num / 1000
	end
	return tostring(math.floor(num*(math.floor(10^decimal_places)))/(math.floor(10^decimal_places))) .. a
end

function addCommas(number)
	if number < 1000 then
		return tostring(math.floor(number))
	end
	local text = tostring(math.floor(number))
	local len = #text
	local output = ""
	for i = 1, len, 1 do
		local char = text:sub(i, i)
		local nextchar = text:sub(i+1, i+1)
		output = output .. char
		if ((len-i) % 3) == 0 then
			if (i ~= len) then
				output = output .. ","
			end
		end
	end
	return output
end

function isMilestone(num, milestone_start)
	num = math.floor(num)
    if num == 0 then
        return true
    end
	if num < milestone_start then
		return false
	end
    local l = math.log10(num)
    return l == math.floor(l)
end

function avg_slice(tbl, start_idx, end_idx)
    local output = 0
	if end_idx > #tbl then end_idx = #tbl end
	if start_idx < 1 then start_idx = 1 end
    for i = start_idx, end_idx do
        output = output + tbl[i]
    end
    return output / ((end_idx-start_idx) + 1)
end

function smoothout(tbl, smoothness)
	local output = {}
	local lenn = #tbl
	for i = lenn, 1, -1 do
		table.insert(output, 1, avg_slice(tbl, i, i+smoothness))
	end
	return output
end

function renderSingleFrame()
    local tick = render_vars.tick -- starts with 0
    local fps = input_vars.fps
    local csv_fps = input_vars.csv_fps
    local csv_tick = math.floor(tick * (csv_fps/fps))
    local graph_length = math.floor(csv_fps * input_vars.graph_duration)

    local bgColor = {love.math.colorFromBytes(hexToRGB(input_vars.bg_color))}

    local textColor = {love.math.colorFromBytes(hexToRGB(input_vars.text_color))}
    local bgbarColor = {love.math.colorFromBytes(hexToRGB(input_vars.hbar_color))}

    local csv_split_index = input_vars.split_index
    local csv_split_chr = input_vars.split_char
    local width = input_vars.width
    local height = input_vars.height
    local graph_zoom_smoothness = input_vars.zoom_smoothness

    local graph_padding_mul = input_vars.padding_mul

    local graph_point_smoothness = input_vars.graph_smoothness

    local abbreviate_number = input_vars.abbreviate_number
    local abbreviate_digits = input_vars.abbreviate_digits

    local line_color = {love.math.colorFromBytes(hexToRGB(input_vars.line_color))}
    local line_thickness = input_vars.line_thickness

    local text_x_offset = input_vars.text_x_offset
    local text_y_offset = input_vars.text_y_offset

    local font = canvas_vars.font
    local font_height = font:getHeight()

    local font_size_mul_milestone = input_vars.text_milestone_scale_mul

    local hbar_thickness = input_vars.hbar_thickness

    local show_text = input_vars.show_text
    local show_bars = input_vars.show_bars

    love.graphics.clear(bgColor)
    
    local tbl_time_data = getCsvTable_Tick(csv_tick, graph_length)

    local values = {} -- values in the current graph range
    local points = {} -- x y points for the line

    for i, v in ipairs(tbl_time_data) do
        local txt = v
        local split = splitBy(txt, csv_split_chr)
        local value = split[csv_split_index]
        table.insert(values, value)
    end

    local max_val = math.max(unpack(values))
    local min_val = math.min(unpack(values))

    canvas_vars.min_zoom = canvas_vars.min_zoom + ( (min_val) - (canvas_vars.min_zoom)) / graph_zoom_smoothness
    canvas_vars.max_zoom = canvas_vars.max_zoom + ( (max_val) - (canvas_vars.max_zoom)) / graph_zoom_smoothness

    local sub = canvas_vars.max_zoom - canvas_vars.min_zoom
    local graph_min_zoom = canvas_vars.min_zoom - (1+(sub*graph_padding_mul))
    local graph_max_zoom = canvas_vars.max_zoom + (1+(sub*graph_padding_mul))
    local graph_sub_zoom = graph_max_zoom - graph_min_zoom

    local a_values = values

    if graph_point_smoothness ~= 0 then
        a_values = smoothout(a_values, graph_point_smoothness)
    end

    for i, v in ipairs(a_values) do -- graph line points
        local value = v
        local x = (i-1)*(width/(graph_length-1))
        local y = height - stretch_num(value, graph_min_zoom, graph_max_zoom, 0, height)
        table.insert(points, x)
        table.insert(points, y)
    end

    -- graph bar lines and the text on it ig
    local line_pow = 10^math.floor(math.log10(graph_sub_zoom))
    local line_pow_b = line_pow

    love.graphics.setLineWidth(hbar_thickness)

    if show_bars then
        for i = 0, 100 do 
            local value = (math.floor(graph_min_zoom/line_pow_b)*line_pow_b + (i/10)*line_pow_b)
            local y = height - stretch_num(value, graph_min_zoom, graph_max_zoom, 0, height)
            if (value >= 0) and (y >= 0 and y <= height) then
                setColor({bgbarColor[1],bgbarColor[2],bgbarColor[3],
                    (bgbarColor[4] or 1) * ((1-((graph_sub_zoom/(line_pow_b*10))%1))/3)
                })
                love.graphics.line(0, y, width, y)
            end
        end
    end

    for i = 0, 10 do 
        local value = math.floor(graph_min_zoom/line_pow)*line_pow + i*line_pow
        local value_text = addCommas(value)
        local is_value_Milestone = isMilestone(value, 1000)
        local text_scale = 1
        if is_value_Milestone then
            text_scale = font_size_mul_milestone
        end
        if abbreviate_number then
            value_text = abbreviate(value, abbreviate_digits)
        end
        local y = height - stretch_num(value, graph_min_zoom, graph_max_zoom, 0, height)
        if (value >= 0) and (y >= 0 and y <= (height*1.5)) then
            if show_bars then
                setColor(bgbarColor)
                love.graphics.line(0, y, width, y)
            end
            if show_text then
                setColor(textColor)
                love.graphics.print(value_text, font, text_x_offset*text_scale, math.floor((y-(font_height*text_scale)) - (text_y_offset * text_scale)), 0, text_scale)
            end
        end
    end

    setColor(line_color)
    love.graphics.setLineWidth(line_thickness)
    love.graphics.line(points)

    if csv_tick - graph_length >= #program.csv then
        program.finish_render = true
    end
end

function frameRenderLoop()
    local end_time = os.clock() + 0.5
    while true do
        program.canvas:renderTo(renderSingleFrame)
        if not program.render_preview then
            renderFrameToFFMPEG_Process()
        end
        if program.finish_render then
            break
        end
        if program.render_preview then
            if not love.keyboard.isDown("down") then
                render_vars.tick=render_vars.tick+1
            end
        else
            render_vars.tick=render_vars.tick+1
        end
        if program.render_preview then
            break
        end
        if os.clock() > end_time then
            break
        end
    end
end


function scaleResolution(width, height, maxwidth, maxheight)
    local scale = math.min(maxwidth / width, maxheight / height)
    if scale < 1 then
        width = width * scale
        height = height * scale
    end
    return { math.floor(width + 0.5), math.floor(height + 0.5) }
end
-- 
function renderCanvasPreview()
    love.graphics.reset()
    if program.render_preview then
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            if love.keyboard.isDown("right") then
                render_vars.tick = math.floor(render_vars.tick + (input_vars.fps))
            end
            if love.keyboard.isDown("left") then
                render_vars.tick = math.floor(render_vars.tick - (input_vars.fps))
            end
        else
            if love.keyboard.isDown("right") then
                render_vars.tick = math.floor(render_vars.tick + (input_vars.fps / 5))
            end
            if love.keyboard.isDown("left") then
                render_vars.tick = math.floor(render_vars.tick - (input_vars.fps / 5))
            end
        end
    end
    if program.canvas then
        local cw = program.canvas:getWidth()
        local ch = program.canvas:getHeight()
        local w = cw
        local h = ch
        local scale = 1

        if (cw > WIDTH) or (ch > HEIGHT) then
            scale = math.min(WIDTH / cw, HEIGHT / ch)
            if scale < 1 then
                w = w * scale
                h = h * scale
            end
        end

        love.graphics.draw(program.canvas, 
            (WIDTH/2 - (w/2)),
            (HEIGHT/2 - (h/2)),
            0, scale)
    end
    local mouseX, mouseY = love.mouse.getPosition()
    local mouse_down = love.mouse.isDown(1)

    local fps = input_vars.fps

    local csv_fps = input_vars.csv_fps
    local csv_length = #program.csv
    
    local graph_dur = math.floor(input_vars.graph_duration * fps)

    local end_tick = (csv_length * (fps / csv_fps)) + graph_dur

    if program.render_preview then
        if mouse_down then
            if mouseY < 48 then
                local p = mouseX / WIDTH
                render_vars.tick = math.floor(p * end_tick)
            end
        end
    end

    local tick = render_vars.tick -- starts with 0

    local render_progress = tick/end_tick

    local top_font = program.fonts["Foldit"]
    local bottom_font = program.fonts["default"]
    local bottom_font_scale = 0.5

    if program.render_preview then
    love.graphics.setColor({0.1,0.1,0})
    else
    love.graphics.setColor({0,0.1,0})
    end
    love.graphics.rectangle("fill", 0, 0, WIDTH, 48)
    if program.render_preview then
    love.graphics.setColor({0.5,0.5,0})
    else
    love.graphics.setColor({0,0.5,0})
    end
    love.graphics.rectangle("fill", 0, 0, WIDTH*render_progress, 48)
    
    local top_font_txt = "[ RENDERING... ]  "
    local top_font_txt_progress = "Frame " .. tick .. " (" .. math.floor(tick/fps) .. "s) / " .. math.floor(end_tick) .. " (" .. math.floor(render_progress*100*10)/10 .. "%)"
    if program.render_preview then
        top_font_txt = "[ PREVIEWING... ]  "
    end
    top_font_txt = top_font_txt .. top_font_txt_progress
    
    love.graphics.setColor({0,0,0,0.5})
    love.graphics.print(top_font_txt, top_font, 14, 14, 0)

    love.graphics.setColor({1,1,1})
    love.graphics.print(top_font_txt, top_font, 10, 10, 0)

    

    love.graphics.setColor({1,1,1})

    if os.clock() >= render_vars.txt_change_time then
        render_vars.txt_change_time = os.clock() + 10
        render_vars.txt_change_txt = program.render_texts[math.random(1, #program.render_texts)]
    end

    local bottom_font_txt = render_vars.txt_change_txt
    love.graphics.print(bottom_font_txt, bottom_font, WIDTH/2 - (bottom_font:getWidth(bottom_font_txt)*bottom_font_scale/2), HEIGHT-60, 0, bottom_font_scale)


end

function onFinish()
    if not program.render_preview then
        program.ffmpegProcess:close()
    end
    print("render took " .. tostring(os.clock() - program.time_since_render) .. " secs")
    print("render tick: " .. render_vars.tick)
    program.sounds.done:play()
    tick.framerate=60
    tick.rate=1/60
end

function renderFrameSwitch()
    love.graphics.reset()

    frameRenderLoop()

    if program.finish_render then
        onFinish()
        program.render=false
        program.finish_render=false
    end
end

function renderButtonSetup(preview)
    if #program.csv == 0 then
        program.sounds.error:play()
        love.window.showMessageBox("MIDI Graph Renderer", "Load a valid CSV file/path before rendering!", "error")
        return
    end
    program.render_preview = preview
    render_vars.txt_change_time = os.clock()
    render_vars.txt_change_txt = ""
    input_vars.width = math.floor(input_vars.width)
    input_vars.height = math.floor(input_vars.height)
    if not program.render then
        canvas_vars.min_zoom=0
        canvas_vars.max_zoom=0
        canvas_vars.font = getFont(input_vars.font, input_vars.font_size)
        if not preview then
            local ffmpegCommand = input_vars.ffmpeg_command
            ffmpegCommand=ffmpegCommand:gsub("{{canvas_width}}",math.floor(input_vars.width))
            ffmpegCommand=ffmpegCommand:gsub("{{canvas_height}}",math.floor(input_vars.height))
            ffmpegCommand=ffmpegCommand:gsub("{{fps}}",input_vars.fps)
            ffmpegCommand=ffmpegCommand:gsub("{{output_path}}",input_vars.output_path)
            ffmpegCommand=ffmpegCommand:gsub("{{frame_size}}",math.floor(input_vars.width*input_vars.height*4))
            program.ffmpegProcess = io.popen(ffmpegCommand, "wb")
        end
        program.canvas=love.graphics.newCanvas(input_vars.width,input_vars.height)
        render_vars.tick = 0
        program.render=true

        if not program.render_preview then
            tick.framerate=nil
            tick.rate=1
        end

        program.time_since_render=os.clock()
    end
end


function input_color_check(val, obj)
    if not val then
        obj.border_color = {255,0,0}
        obj.button_color = {125,100,100}
    else
        obj.border_color = {0,255,0}
        obj.button_color = {100,125,100}
    end
end

function hexToRGB(hex)
    local hex = hex:gsub("#", "")
    if hex:match("^%x%x%x%x%x%x$") then
        return {tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)}
    elseif hex:match("^%x%x%x%x%x%x%x%x$") then
        return {tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), tonumber(hex:sub(7, 8), 16)}
    else
        return nil
    end
end

function hsvToRGB(h, s, v)
    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return {math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)}
end


program.font_list_text = ""
for k, v in pairs(program.font_paths) do
    program.font_list_text = program.font_list_text .. '' .. k .. ", "
end
program.font_list_text = program.font_list_text:sub(1, #program.font_list_text - 2)


function love.load()
    print("Program started")
    print("Font list: " .. program.font_list_text)
    print("Save path: " .. love.filesystem.getSaveDirectory() )

    program.ui.program_title = ui.new_Text({
        x=5,y=5,
        text="MIDI Graph Renderer by Danidanijr",
        text_scale=2
    })
    program.ui.program_love2dcredit = ui.new_Text({
        x=5,y=HEIGHT-5,
        text="Version " .. program.VERSION .. " - Made with LÖVE2D",
        text_middle_align="bottom"
    })

    -- input stuff
    program.ui.csv_input_path = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        text_align="left",
        w=640,
        x=5,y=45,
        text="Write .CSV file (exported by Zenith 2) path here. (You can also paste text here)",
    })
    program.ui.csv_input_path_load_status = ui.new_Text({
        x=710,y=45+4,
        text="Status: Unloaded",
    })
    program.ui.csv_input_path_load = ui.new_Button({
        x=650,y=45,
        w=50,
        text="Load",
        on_click=function (obj)
            playButton()
            local path = program.ui.csv_input_path.text
            local file = io.open(path, "r")
            if file then
                program.csv = {}
                for line in file:lines() do
                    table.insert(program.csv, line)
                end
                file:close()
                program.ui.csv_input_path_load_status.text = "Status: Success! CSV Lines: " .. #program.csv
            else
                program.ui.csv_input_path_load_status.text = "Status: Error opening file"
                program.csv = {}
            end
            
        end
    })

    program.ui.csv_fps_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="number",
        input_var="csv_fps",
        w=50,
        x=5,y=75,
        text=tostring(input_vars.csv_fps)..".0",
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.csv_fps = parseNumText(val, 60)
        end
    })
    program.ui.csv_fps_input_hint = ui.new_Text({
        x=50+15,y=75+4,
        text="FPS rate of the .CSV file",
    })

    program.ui.csv_split_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="char",
        input_var="split_char",
        w=20,
        x=300,y=75,
        text=tostring(input_vars.split_char),
        on_text_change=function (obj)
            input_vars.split_char = obj.text
        end
    })
    program.ui.csv_split_input_hint = ui.new_Text({
        x=300+30,y=75+4,
        text="Char. to split each line with.",
    })

    program.ui.csv_split_index_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="int",
        input_var="split_index",
        w=30,
        x=550,y=75,
        text=tostring(input_vars.split_index),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.split_index = parseNumText(val, 1)
        end
    })
    program.ui.csv_split_index_input_hint = ui.new_Text({
        x=550+40,y=75+4,
        text="CSV Split index to use, By default on Zenith 2, 1=NPS, 2=Polyphony, etc.",
    })

    program.ui.canvas_width_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="int",
        input_var="width",
        w=50,
        x=5,y=105,
        text=tostring(input_vars.width),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.width = parseNumText(val, 640)
        end
    })
    program.ui.canvas_height_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="int",
        input_var="height",
        w=50,
        x=83,y=105,
        text=tostring(input_vars.height),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.height = parseNumText(val, 360)
        end
    })
    program.ui.canvas_size_x_txt = ui.new_Text({
        x=50+15,y=105+4,
        text="x",
    })
    program.ui.canvas_size_txt = ui.new_Text({
        x=130+15,y=105+4,
        text="Video Resolution",
    })

    program.ui.video_fps_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="int",
        input_var="fps",
        w=50,
        x=300,y=105,
        text=tostring(input_vars.fps),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.fps = parseNumText(val, 60)
        end
    })
    program.ui.video_fps_input_hint = ui.new_Text({
        x=300+60,y=105+4,
        text="Video FPS",
    })

    program.ui.font_size_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="int",
        input_var="font_size",
        w=50,
        x=160,y=135,
        text=tostring(input_vars.font_size),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.font_size = parseNumText(val, 24)
        end
    })

    program.ui.font_input_text_preview = ui.new_Text({
        x=5+215,y=135+5,
        text="The font and size to use in the graph video.  AaBbCc 1,234,567,890  123.456K  789M",
        font=getFont("Foldit", 14)
    })
    program.ui.font_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="text",
        input_var="font",
        w=150,
        x=5,y=135,
        text=tostring(input_vars.font),
        on_text_change=function (obj)
            local val = obj.text
            if program.font_paths[val] then
                input_vars.font = val
                program.ui.font_input_text_preview.font = getFont(val, 14)
            else
                input_vars.font = "default"
                program.ui.font_input_text_preview.font = getFont("default", 14)
            end
        end
    })

    program.ui.font_input_text_list = ui.new_Text({
        x=5,y=135+30,
        text="LÖVE2D doesn't has a function to load custom font from the system (As i'm aware of) So you have to type which font you want below: (CASE-SENSITIVE!)\n" .. program.font_list_text
    })

    program.ui.bg_color_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="color",
        input_var="bg_color",
        w=100,
        x=5,y=205,
        text=tostring(input_vars.bg_color),
        border_color = {0,0,0},button_color = {0,0,0},
        on_text_change=function (obj)
            local val = obj.text
            local cor = hexToRGB(val)
            if cor then
                input_vars.bg_color = val
                obj.border_color = cor
                obj.button_color = {cor[1]/2, cor[2]/2, cor[3]/2}
            else
                input_vars.bg_color = "#000000"
                obj.border_color = {0,0,0}
                obj.button_color = {0,0,0}
            end
        end
    })
    program.ui.bg_color_input_hint = ui.new_Text({
        x=5+110,y=205+4,
        text="Background color."
    })

    program.ui.line_color_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="color",
        input_var="line_color",
        w=100,
        x=260,y=205,
        border_color = {0,255,255},button_color = {0,127,127},
        text=tostring(input_vars.line_color),
        on_text_change=function (obj)
            local val = obj.text
            local cor = hexToRGB(val)
            if cor then
                input_vars.line_color = val
                obj.border_color = cor
                obj.button_color = {cor[1]/2, cor[2]/2, cor[3]/2}
            else
                input_vars.line_color = "#00ffff"
                obj.border_color = {0,255,255}
                obj.button_color = {0,127,127}
            end
        end
    })
    program.ui.line_color_input_hint = ui.new_Text({
        x=260+110,y=205+4,
        text="Graph line color."
    })

    program.ui.text_color_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="color",
        input_var="text_color",
        w=100,
        x=500,y=205,
        text=tostring(input_vars.text_color),
        border_color = {255,255,255,127},button_color = {127,127,127},
        on_text_change=function (obj)
            local val = obj.text
            local cor = hexToRGB(val)
            if cor then
                input_vars.text_color = val
                obj.border_color = cor
                obj.button_color = {cor[1]/2, cor[2]/2, cor[3]/2}
            else
                input_vars.text_color = "#FFFFFF7F"
                obj.border_color = {255,255,255,127}
                obj.button_color = {127,127,127}
            end
        end
    })
    program.ui.text_color_input_hint = ui.new_Text({
        x=500+110,y=205+4,
        text="Text color."
    })

    program.ui.hbar_color_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="color",
        input_var="hbar_color",
        w=100,
        x=700,y=205,
        text=tostring(input_vars.hbar_color),
        border_color = {255,255,255,127},button_color = {127,127,127},
        on_text_change=function (obj)
            local val = obj.text
            local cor = hexToRGB(val)
            if cor then
                input_vars.hbar_color = val
                obj.border_color = cor
                obj.button_color = {cor[1]/2, cor[2]/2, cor[3]/2}
            else
                input_vars.hbar_color = "#FFFFFF7F"
                obj.border_color = {255,255,255,127}
                obj.button_color = {127,127,127}
            end
        end
    })
    program.ui.hbar_color_input_hint = ui.new_Text({
        x=700+110,y=205+4,
        text="Background bar color."
    })





    -- graph_duration
    program.ui.graph_duration_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="number",
        input_var="graph_duration",
        w=50,
        x=5,y=235,
        text=tostring(input_vars.graph_duration) .. ".0",
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.graph_duration = parseNumText(val, 2.0)
        end
    })
    program.ui.graph_duration_input_hint = ui.new_Text({
        x=5+60,y=235+4,
        text="Range duration of the graph in secs."
    })

    program.ui.zoom_smoothness_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="number",
        input_var="zoom_smoothness",
        w=50,
        x=5,y=265,
        text=tostring(input_vars.zoom_smoothness) .. ".0",
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.zoom_smoothness = parseNumText(val, 2.0)
        end
    })
    program.ui.zoom_smoothness_input_hint = ui.new_Text({
        x=5+60,y=265+4,
        text="Animation smoothness of the graph zoom, Higher = More smoother"
    })

    program.ui.graph_smoothness_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="int",
        input_var="graph_smoothness",
        w=50,
        x=550,y=265,
        text=tostring(input_vars.graph_smoothness),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.graph_smoothness = parseNumText(val, 0)
        end
    })
    program.ui.graph_smoothness_input_hint = ui.new_Text({
        x=550+60,y=265+4,
        text="Smoothness of the graph, Higher = More smoother, but it'll look more straight-ish? (0 = off)"
    })

    -- text_milestone_scale_mul
    program.ui.text_milestone_scale_mul_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="number",
        input_var="text_milestone_scale_mul",
        w=50,
        x=5,y=295,
        text=tostring(input_vars.text_milestone_scale_mul),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.text_milestone_scale_mul = parseNumText(val, 1.5)
        end
    })
    program.ui.text_milestone_scale_mul_input_hint = ui.new_Text({
        x=5+60,y=295+4,
        text="Text size amplification on milestones like 1k, 10k, 100k, etc"
    })


    -- padding_mul
    program.ui.padding_mul_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="number",
        input_var="padding_mul",
        w=50,
        x=5,y=325,
        text=tostring(input_vars.padding_mul),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.padding_mul = parseNumText(val, 0.1)
        end
    })
    program.ui.padding_mul_input_hint = ui.new_Text({
        x=5+60,y=325+4,
        text="Graph Max-Min zoom padding amplification"
    })

    -- line_thickness, hbar_thickness
    program.ui.line_thickness_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="number",
        input_var="line_thickness",
        w=50,
        x=5,y=355,
        text=tostring(input_vars.line_thickness),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.line_thickness = parseNumText(val, 3)
        end
    })
    program.ui.line_thickness_input_hint = ui.new_Text({
        x=5+60,y=355+4,
        text="Line thickness of the graph."
    })

    program.ui.hbar_thickness_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="number",
        input_var="hbar_thickness",
        w=50,
        x=300,y=355,
        text=tostring(input_vars.hbar_thickness),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.hbar_thickness = parseNumText(val, 1)
        end
    })
    program.ui.hbar_thickness_input_hint = ui.new_Text({
        x=300+60,y=355+4,
        text="Background horizontal bars thickness of the graph."
    })

    program.ui.text_x_offset_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="number",
        input_var="text_x_offset",
        w=50,
        x=5,y=385,
        text=tostring(input_vars.text_x_offset),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.text_x_offset = parseNumText(val, 2)
        end
    })
    program.ui.text_y_offset_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="number",
        input_var="text_y_offset",
        w=50,
        x=60,y=385,
        text=tostring(input_vars.text_y_offset),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.text_y_offset = parseNumText(val, 2)
        end
    })
    program.ui.text_offset_input_hint = ui.new_Text({
        x=60+60,y=385+4,
        text="X & Y position offset of the text on the graph."
    })

    -- toggle stuff
    -- toggle stuff
    -- toggle stu
    -- toggle stuff
    local y_offset = 190

    program.ui.toggle_bg = ui.new_Button({
        w=175,
        h=20,
        x=5,y=HEIGHT-60,
        border_color = {0,255,0},button_color = {0,127,0},
        text="Disable BG Shader",
        on_click=function (obj)
            playButton()
            if program.disable_bg then
                program.disable_bg = false
                obj.text = "Disable BG Shader"
                obj.border_color = {0,255,0}
                obj.button_color = {0,127,0}
            else
                program.disable_bg = true
                obj.text = "Enable BG Shader"
                obj.border_color = {255,0,0}
                obj.button_color = {127,0,0}
            end
        end
    })
    program.ui.toggle_bg_text = ui.new_Text({
        x=190,y=HEIGHT-57,
        text="Disables the program's background gradient. (Performance Mode)",
        font=program.small_font
    })

    program.ui.abbreviate_number_toggle = ui.new_Button({
        input_var="abbreviate_number",
        input_check_type="boolean",
        w=25,
        x=5,y=y_offset+235,
        border_color = {255,0,0},button_color = {127,0,0},
        text="N",
        on_click=function (obj)
            playButton()
            if input_vars.abbreviate_number then
                input_vars.abbreviate_number = false
                obj.text = "N"
                obj.border_color = {255,0,0}
                obj.button_color = {127,0,0}
            else
                input_vars.abbreviate_number = true
                obj.text = "Y"
                obj.border_color = {0,255,0}
                obj.button_color = {0,127,0}
            end
        end
    })
    program.ui.abbreviate_number_toggle_hint = ui.new_Text({
        x=40,y=y_offset+235+4,
        text="To abbreviate the number shown left on the graph."
    })

    program.ui.abbreviate_digits_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        input_check_type="int",
        input_var="abbreviate_digits",
        w=30,
        x=450,y=y_offset+235,
        text=tostring(input_vars.abbreviate_digits),
        on_text_change=function (obj)
            local val = tonumber(obj.text)
            input_color_check(val, obj)
            input_vars.abbreviate_digits = parseNumText(val, 3)
        end
    })
    program.ui.abbreviate_digits_input_hint = ui.new_Text({
        x=490,y=y_offset+235+4,
        text="If abbreviated, How many max decimal digits to show?"
    })

    program.ui.show_text_toggle = ui.new_Button({
        input_var="show_text",
        input_check_type="boolean",
        w=25,
        x=5,y=y_offset+265,
        border_color = {0,255,0},button_color = {0,127,0},
        text="Y",
        on_click=function (obj)
            playButton()
            if input_vars.show_text then
                input_vars.show_text = false
                obj.text = "N"
                obj.border_color = {255,0,0}
                obj.button_color = {127,0,0}
            else
                input_vars.show_text = true
                obj.text = "Y"
                obj.border_color = {0,255,0}
                obj.button_color = {0,127,0}
            end
        end
    })
    program.ui.show_text_toggle_hint = ui.new_Text({
        x=40,y=y_offset+265+4,
        text="To show the text number shown left on the graph."
    })

    --show_bars
    program.ui.show_bars_toggle = ui.new_Button({
        input_var="show_bars",
        input_check_type="boolean",
        w=25,
        x=5,y=y_offset+295,
        border_color = {0,255,0},button_color = {0,127,0},
        text="Y",
        on_click=function (obj)
            playButton()
            if input_vars.show_bars then
                input_vars.show_bars = false
                obj.text = "N"
                obj.border_color = {255,0,0}
                obj.button_color = {127,0,0}
            else
                input_vars.show_bars = true
                obj.text = "Y"
                obj.border_color = {0,255,0}
                obj.button_color = {0,127,0}
            end
        end
    })
    program.ui.show_bars_toggle_hint = ui.new_Text({
        x=40,y=y_offset+295+4,
        text="To show the horizontal line bars on the graph."
    })

    -- use_transparency_mask

    program.ui.use_transparency_mask_toggle = ui.new_Button({
        input_var="use_transparency_mask",
        input_check_type="boolean",
        w=25,
        x=5,y=y_offset+325,
        border_color = {255,0,0},button_color = {127,0,0},
        text="N",
        on_click=function (obj)
            playButton()
            if input_vars.use_transparency_mask then
                input_vars.use_transparency_mask = false
                obj.text = "N"
                obj.border_color = {255,0,0}
                obj.button_color = {127,0,0}
            else
                input_vars.use_transparency_mask = true
                obj.text = "Y"
                obj.border_color = {0,255,0}
                obj.button_color = {0,127,0}
            end
        end
    })
    program.ui.use_transparency_mask_toggle_hint = ui.new_Text({
        x=40,y=y_offset+325+4,
        text="Use transparency mask (Enabling this will basically only render colors in black and white, Except the background color.)"
    })

    --
    --
    --
    --
    --

    program.ui.output_path_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        text_align="left",
        w=640,
        x=5,y=600,
        text="output.mp4",
        on_text_change=function (obj)
            input_vars.output_path = obj.text
        end
    })
    program.ui.output_path_input_hint = ui.new_Text({
        x=5,y=560,
        text="Video output path and the ffmpeg.exe command it will execute for rendering the video.\n{{fps}} = Video FPS, {{canvas_width}} = Video Width, {{canvas_height}} = Video Height, {{output_path}} = Output path"
    })
    
    program.ui.ffmpeg_command_input = ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        text_align="left",
        w=1200,
        h=21,
        x=5,y=630,
        text=input_vars.ffmpeg_command,
        input_var="ffmpeg_command",
        font=program.small_font,
        on_text_change=function (obj)
            input_vars.ffmpeg_command = obj.text
        end
    })



    --program.ui.progaa = ui.new_Button({
    --    x=10,y=10,
    --    text="Export Test",
    --    on_click=function (obj)
    --        renderButtonSetup(false)
    --    end
    --})

    program.ui.test_preview = ui.new_Button({
        x=WIDTH-150,y=HEIGHT-40,
        w=125,
        text="Preview Render",
        on_click=function (obj)
            playButton()
            renderButtonSetup(true)
        end
    })
    program.ui.text_export = ui.new_Button({
        x=WIDTH-290,y=HEIGHT-40,
        w=125,
        text="Export!",
        on_click=function (obj)
            playButton()
            renderButtonSetup(false)
        end
    })

    program.render_ui.stop_render = ui.new_Button({
        x=(WIDTH/2)-(150/2),y=HEIGHT-40,
        w=150,
        text="End Render [HOLD]",
        on_click=function (obj)
            program.finish_render = true
        end
    })

    program.ui.dani_button = ui.new_Button({
        x = (WIDTH-75)-7,
        y = 7,
        w = 75,
        h = 75,
        text="",
        button_color = {0,0,0,0},
        border_color = {0,0,0,0},
        border_hover_color = {0,0,0,0},
        button_hover_color = {0,255,255,64},
        on_click = function ()
            playButton()
            love.system.openURL("https://www.youtube.com/@Danidanijr")
        end
    })

    program.ui.preset_title = ui.new_Text({
        x=WIDTH-185,y=330,
        text="Presets",
        text_align="center",
        text_scale=2
    })
    program.ui.preset_desc = ui.new_Text({
        x=WIDTH-340,y=367,
        text="You can save & load presets below!\nPretty cool, huh?",
    })
    
    program.ui.preset_input= ui.new_Button({
        button_type=ui.types.ButtonType.INPUT,
        x=WIDTH-340,y=410,
        w=205,
        h=20,
        text_align="left",
        text="Preset Name"
    })
    program.ui.preset_save = ui.new_Button({
        x=WIDTH-130,y=410,
        w=45,
        h=20,
        text="Save",
        on_click=function (obj)
            playButton()
            savePreset(program.ui.preset_input.text)
        end
    })
    program.ui.preset_load = ui.new_Button({
        x=WIDTH-80,y=410,
        w=45,
        h=20,
        text="Load",
        on_click=function (obj)
            playButton()
            loadPreset(program.ui.preset_input.text)
        end
    })

    program.ui.preset_open_dir = ui.new_Button({
        x=WIDTH-340,y=445,
        w=305,
        h=20,
        text="Open Presets Folder",
        on_click=function (obj)
            playButton()
            local folderPath = love.filesystem.getSaveDirectory()
            local command = folderPath
            if love.system.getOS() == "Windows" then
                command = 'start "" "' .. folderPath .. '"'
            elseif love.system.getOS() == "OS X" then
                command = 'open "' .. folderPath .. '"'
            else
                command = 'xdg-open "' .. folderPath .. '"'
            end
            os.execute(command)
        end
    })


    for k, v in pairs(program.ui) do
        if type(v) == "table" then
            if v._type == ui.types.BUTTON then
                if v.button_type == ui.types.ButtonType.INPUT then
                    for kk, vv in pairs(program.text_input_style) do
                        v[kk] = vv
                    end
                end
            end
        end
    end
end

function loadPreset(name)
    if love.filesystem.exists(name .. ".json") then
        local decoded = json.decode(love.filesystem.read(name .. ".json"))
        for k, v in pairs(program.ui) do
            if type(v) == "table" then
                if v._type == ui.types.BUTTON then
                    if v.input_var then
                        local var_name = v.input_var -- var names of the objects like show_bars, use_transparency_mask, etc
                        local value = decoded[var_name]
                        input_vars[var_name] = value
                        v.text = tostring(value)
                        if v.input_check_type then
                            if v.input_check_type == "boolean" then
                                if value then
                                    v.text = "Y"
                                    v.border_color = {0,255,0}
                                    v.button_color = {0,127,0}
                                else
                                    v.text = "N"
                                    v.border_color = {255,0,0}
                                    v.button_color = {127,0,0}
                                end
                            end
                            if v.input_check_type == "color" then
                                local cor = hexToRGB(value)
                                if cor then
                                    v.border_color = cor
                                    v.button_color = {cor[1]/2,cor[2]/2,cor[3]/2}
                                else
                                    v.border_color = {255,0,0}
                                    v.button_color = {191,0,0}
                                end
                            end
                            if v.input_check_type == "number" or v.input_check_type == "int" then
                                v.button_color = {100,100,100}
                                v.border_color = {255,255,255}
                            end
                        end
                    end
                end
            end
        end
        print("Loaded preset: " .. love.filesystem.getSaveDirectory() .. "/" .. name .. ".json")
    else
        program.sounds.error:play()
        love.window.showMessageBox("MIDI Graph Renderer", "Preset '" .. name .. "' does not exist!", "error")
    end
end

function savePreset(name)
    local text = json.encode(input_vars)
    local decoded = json.decode(text)
    decoded["output"] = nil
    text = json.encode(decoded)
    love.filesystem.write(name .. ".json", text)
    print("Saved preset to: " .. love.filesystem.getSaveDirectory() .. "/" .. name .. ".json")
end

function love.update()
    if program.render then
        renderFrameSwitch()
    end
end

love.graphics.setBackgroundColor(0.1, 0.2, 0.3, 1)

local bg_tick=0
function love.draw()
    if program.render then
        if program.disable_bg then
            love.graphics.clear({0,0.25,0.25})
        else
            ui.draw_shader.hgradientRect(0, 0, WIDTH, HEIGHT, program.bg_render_gradient[1], program.bg_render_gradient[2])
        end
        renderCanvasPreview()
        ui.render(program.render_ui)
    else
        if program.disable_bg then
            love.graphics.clear({0,0.25,0.25})
        else
            local colorA = hsvToRGB(bg_tick/1000, 1, 1)
            colorA = {colorA[1]/4,colorA[2]/4,colorA[3]/4}
            local colorB = hsvToRGB((bg_tick/1000) + 30/360, 1, 1)
            colorB = {colorB[1]/4,colorB[2]/4,colorB[3]/4}
            ui.draw_shader.hgradientRect(0, 0, WIDTH, HEIGHT, colorA, colorB)
        end
        love.graphics.draw(program.images.danidanijr, (WIDTH - 75) - 7, 7)
        love.graphics.setColor({0,0,0,0.5})
        love.graphics.rectangle("fill", WIDTH-350, 325, 325, 150)
        ui.render(program.ui)
        bg_tick = bg_tick + 1
    end
    ui.tick()
end