--------- GUI ------------

--Main_Menu formspec for trifle
trifle.menu_set = nil --when menu set is nil, default menu mode will load
function trifle.main_menu()
    --Header
    local r = {
        "formspec_version[3]",
        "size[11,11]",
        "position[0.5,0.5]",
        "anchor[0.5,0.5]",
        "no_prepend[]",
        "bgcolor[#DFE0EDD0;both;#00000080]",
        "box[0.5,1.5;10,9;#FFF7]",
    }
    if not trifle.menu_set then
        local sets = trifle.levels.num
        --title
        table.insert(r,"hypertext[1,0.1;9,2;;")
        table.insert(r,"<global halign=center color=#03A size=32 font=Regular>")
        table.insert(r,"Trifle, a puzzle game!")
        table.insert(r,"<global halign=left color=#000 size=16 font=Regular>\n")
        table.insert(r,"Select a set of levels:]")
        --Scroll container containing setnames with icons:
        table.insert(r,"scroll_container[0.5,2;10,9;scroll;vertical;0.1]")
        --for each set, output the icon and set_name as a button
        for i=1, sets, 1 do
            local name = trifle.levels[i]
            table.insert(r,"box[0.13,"..((i-1)*1.8+0.1)..";0.16,1.4;#0B35]")
            table.insert(r,"image[0.5,"..((i-1)*1.8)..";1.6,1.6;"..trifle.levels[name].icon.."]")
            table.insert(r,"button[3,"..((i-1)*1.8+0.3)..";5,1;set"..i..";".. name.."]")
        end
        table.insert(r,"scroll_container_end[]")
        table.insert(r,"scrollbaroptions[max="..(sets*34)..";thumbsize="..(sets*4).."]")
        table.insert(r,"scrollbar[10.0,2;0.5,8;vertical;scroll;0]")
    else --match trifle.menu_set against registered sets:
        local set = trifle.levels[trifle.menu_set]
        local levels = trifle.levels[set].num
        --title
        table.insert(r,"hypertext[1,0.1;9,2;;")
        table.insert(r,"<global halign=center color=#03A size=32 font=Regular>")
        table.insert(r,tostring(set).."]")
        table.insert(r,"button[0.1,0.1;2,1;back;back]")
        table.insert(r,"image[9.7,0.1.2;1.2,1.2;"..trifle.levels[set].icon.."]")
        --Scroll container containing setnames with icons:
        table.insert(r,"scroll_container[0.5,2;10,9;scroll;vertical;0.1]")
        --for each set, output the icon and set_name as a button
        for i=1, levels, 1 do
            local name = trifle.levels[set][i].name
            local icon = trifle.levels[set][i].icon
            table.insert(r,"box[0.13,"..((i-1)*1.8+0.1)..";0.16,1.4;#0B35]")
            table.insert(r,"image[0.5,"..((i-1)*1.8)..";1.6,1.6;"..icon.."]")
            table.insert(r,"hypertext[2.3,"..((i-1)*1.8+0.5)..";0.4,1;;")
            table.insert(r,"<global halign=left color=#0B35 size=24 font=Regular>")
            table.insert(r,i.."]")
            table.insert(r,"button_exit[3,"..((i-1)*1.8+0.3)..";5,1;level"..i..";".. name.."]")
        end
        table.insert(r,"scroll_container_end[]")
        table.insert(r,"scrollbaroptions[max="..(levels*34)..";thumbsize="..(levels*4).."]")
        table.insert(r,"scrollbar[10.0,2;0.5,8;vertical;scroll;0]")
    end
    table.insert(r,"")
    return table.concat(r);
end

-----------------Introductory Formspec--------------------------
--
-- trifle.intro(intro_def)
-- intro_def = { 
--                title   = string
--                Message = string
--                ftsize  = integer
--                bgcolor = ColorString
--             }
--
-- 1. Shows the introductory formspec to the user
-- 2. Keeps the game unloaded until recieved.
-------------------------------------------------------------
function trifle.intro(intro_def)
    local intro = intro_def
    
    --Parse the intro
    if not intro.title   then trifle.warn_and_quit("No title specified for intro"); return false end
    local title = intro. title
    if not intro.message then trifle.warn_and_quit("No message specified for intro"); return false end
    local message = intro.message
    local bgcolor = "#FFFA"
    if intro.bgcolor then bgcolor = intro.bgcolor end
    local ftsize = 16
    if intro.ftsize then ftsize = intro.ftsize end
    
    --create the formspec
    local f = {
        "formspec_version[3]",
        "size[8,10]",
        "position[0.5,0.5]",
        "anchor[0.5,0.5]",
        "no_prepend[]",
        "bgcolor["..bgcolor..";both;#333333A0]",
        "hypertext[0.5,0.2;7,7.8;;",
        "<global halign=center color=#222 size=32 font=Regular>",title,
        "<global halign=center color=#000 size="..ftsize.." font=Regular>\n",message,"]",
        "button_exit[2.5,8.5;3,1;begin;Begin]",
        "image[6.9,0.1;1,1;"..tostring(trifle.current_level.icon).."]",
    }
    
    --send the formspec
    minetest.show_formspec("singleplayer", "trifle_core:intro", table.concat(f))
    return true
end

----------------------------------------------------------
--
-- trifle.onRecieveFields(player, formname, fields)
--
-- player: player object 
-- formname: use provided form name
-- fields: standard recieve fields
-- Callback for on_recieve fields
----------------------------------------------------------
function trifle.onRecieveFields(player, formname, fields)
    if formname == "trifle_core:intro" then trifle.loaded = true; return end
    if formname == "trifle_core:victory" then
        if fields.next then trifle.load_level(trifle.levels[trifle.menu_set], trifle.current_level.level_number+1) 
        else 
            trifle.menu_set = nil
            minetest.after(0.05, function() minetest.show_formspec(player:get_player_name(), "trifle_core:main_menu", trifle.main_menu()) end) 
        end
        return
    end
    if formname == "trifle_core:failure" then
        if fields.retry then trifle.load_level(trifle.levels[trifle.menu_set], trifle.current_level.level_number) 
        else
            trifle.menu_set = nil
            minetest.after(0.05, function() minetest.show_formspec(player:get_player_name(), "trifle_core:main_menu", trifle.main_menu()) end) 
        end
        return
    end
    if formname ~= "trifle_core:main_menu" then return end

    if fields.back then
        trifle.menu_set = nil
        minetest.after(0.05, function() minetest.show_formspec(player:get_player_name(), "trifle_core:main_menu", trifle.main_menu()) end)
        return
    end
    --Loop through all fields
    for name,_ in pairs(fields) do
        if string.sub(name,1,3) == "set" then
            trifle.menu_set = tonumber(string.sub(name,4,-1))
            minetest.show_formspec(player:get_player_name(), "trifle_core:main_menu", trifle.main_menu())
            return
        elseif string.sub(name,1,5) == "level" then
            if trifle.menu_set ~= nil then
                trifle.load_level(trifle.levels[trifle.menu_set], tonumber(string.sub(name,6,-1)))
                return
            end
        end
    end
    --If after all that, nothing is set, they used escape to quit.
    if fields.quit then
        minetest.after(0.05, function() minetest.show_formspec(player:get_player_name(), "trifle_core:main_menu", trifle.main_menu()) end)
    return
    end
    --local setname = trifle.levels[trifle.levels.num]
    --trifle.load_level(setname, 1)
end

minetest.register_on_player_receive_fields(function(player, formname, fields) trifle.onRecieveFields(player, formname, fields) end)

----------------------------------------------------------
--
-- trifle.load_hud(player)
--
-- player: player object 
-- 
-- Readies the normal in-game HUD, which includes:
--
-- Messages Panel (left side)
-- Objectives Panel (right-bottom corner)
-- Normal item boxes (on bottom)
-- Level Info Panel (top right)
-- Current Round Number (top-middle)
--
----------------------------------------------------------
function trifle.load_hud(player)

-----------------------------
--Messages Panel (left side)
-----------------------------
    trifle.hud.message_image = player:hud_add({
        hud_elem_type = "image",
        position  = {x = 0, y = 1},
        scale     = {x = 9, y = 14},
        text      = "back.png",
        alignment = { x = 1, y = -1},
        offset    = {x = 10, y = -20},
        z_index = -8,
    })
    
    trifle.hud.message_title = player:hud_add({
        hud_elem_type = "text",
        position  = {x = 0, y = 1},
        offset    = {x = 85, y = -405},
        name      = "message_title",
        text      = "Messages",
        number    = 0x000, --Color
        size      = { x = 2, y = 2},
        alignment = { x = 1, y = -1},
        z_index = -8,
    })
    
    trifle.hud.messages = player:hud_add({
        hud_elem_type = "text",
        position  = {x = 0, y = 1},
        offset    = {x = 40, y = -405},
        number    = 0x303000, --Color
        size      = { x = 1, y = 1},
        alignment = { x = 1, y = 1 },
        name      = "messages",
        z_index = -8,
        text      = [[
------------Info------------
 These messages can contain any 
     information you want
    But, you are limited to
   ~4 lines * 34 characters.
  
----------Warning-----------
 You can display warnings as 
 well, such as this. There 
 is a more menacing message:
 -
 
<<<<<ALERT>>>>>
 This is used for the most
 important of messages.
 -
 -
]],
    })
    
-----------------------------
--Objectives Panel (right-bottom corner)
-----------------------------
    trifle.hud.message_image = player:hud_add({
        hud_elem_type = "image",
        position  = {x = 1, y = 1},
        scale     = {x = 7, y = 9},
        text      = "back.png",
        alignment = { x = -1, y = -1 },
        offset    = {x = -5, y = -10},
        z_index = -8,
        
    })
    
    trifle.hud.message_title = player:hud_add({
        hud_elem_type = "text",
        position  = {x = 1, y = 1},
        offset    = {x = -44, y = -245},
        name      = "message_title",
        text      = "Objectives",
        number    = 0x000, --Color
        size      = { x = 2, y = 2},
        alignment = { x = -1, y = -1 },
        z_index = -8,
    })
    
    trifle.hud.messages = player:hud_add({
        hud_elem_type = "text",
        position  = {x = 1, y = 1},
        offset    = {x = -25, y = -245},
        number    = 0x005020, --Color
        size      = { x = 1, y = 1},
        alignment = { x = -1, y = 1 },
        name      = "messages",
        z_index = -8,
        text      = [[
1. Survive to Round 50

2. Have at least 20 Life
at Round 50.

3. Never drop below 10 Life
]],
    })
    
-----------------------------
--Normal item boxes (on bottom)
-----------------------------
    --Level Info Panel (top right)
    
    trifle.hud.level_back = player:hud_add({
        hud_elem_type = "image",
        position  = {x = 1, y = 0},
        scale     = {x = 6, y = 4},
        text      = "back.png",
        alignment = { x = -1, y = 1},
        offset    = { x = -5, y = 5},
        z_index = -8,
    })
    
    trifle.hud.level_num_name = player:hud_add({
        hud_elem_type = "text",
        position  = {x = 1, y = 0},
        offset    = {x = -100, y = 130},
        name      = "round",
        text      = "Level: 1\nName: Intro\nSet: Tutorial",
        number    = 0x000000, --Color
        size      = { x = 1, y = 1},
        alignment = { x = -1, y = -1 },
        z_index = -8,
    })
    
    trifle.hud.level_back = player:hud_add({
        hud_elem_type = "image",
        position  = {x = 1, y = 0},
        scale     = {x = 2.4, y = 2.4},
        text      = "tutorial_icon.png",
        alignment = { x = -1, y = 1},
        offset    = { x = -11, y = 9.5},
        z_index = -8,
    })
    
    
    --Current Round Number (top-middle)

    -- Round Number
    trifle.hud.round = player:hud_add({
        hud_elem_type = "text",
        position  = {x = 0.5, y = 0},
        offset    = {x = 0, y = 30},
        name      = "round",
        text      = "1",
        number    = 0x009999, --Color
        size      = { x = 3, y = 1},
        alignment = { x = 0, y = 0 },
        z_index = -8,
    })
end

----------------------------------------------------------
--
-- trifle.do_victory(spec)
--
-- returns the do_victory() function
-- based on the provided spec table:
--  spec = {
--       title = "title",  The title is at the top
--       message = "message",  And the text below is shown below the title, 
--              keep in mind text can be colored <style color=colorstring> before the text in question.
--       ftsize  = Message Font size. Title is 32. Default is 16.
--       bgcolor = "color", --formats are #RGBA, #RGB, #RRGGBB, #RRGGBBAA or "red", "blue", "etc"
--      }
--
----------------------------------------------------------
function trifle.do_victory(spec)
    local title   = "Victory!"
    local message    = "Congradulations, good job solving this challenge!"
    local bgcolor = "#BBBBBBFF"
    local ftsize  = 18
    if spec then --only do something if not nil
        if spec.title then title = spec.title end
        if spec.message then message  = spec.message end
        if spec.ftsize then ftsize  = spec.ftsize end
        if spec.bgcolor then bgcolor  = spec.bgcolor end
    end
    -- function to return
    return function()
        local set = trifle.current_level.setname
        local levelnum = trifle.current_level.level_number
        local show_next = "" --for showing the "next level button" or ""
        local back = "button_exit[2,8.5;4,1;back;Main Menu]"
        if trifle.levels[set].num > levelnum then
            show_next = "button_exit[4.5,8.5;2,1;next;Next Level]"
            back = "button_exit[1.5,8.5;2,1;back;Main Menu]"
        end
        local form = {
            "formspec_version[3]",
            "size[8,10]",
            "position[0.5,0.5]",
            "anchor[0.5,0.5]",
            "no_prepend[]",
            "bgcolor["..bgcolor..";both;#333333A0]",
            "hypertext[0.5,0.2;7,7.8;;",
            "<global halign=center color=#222 size=32 font=Regular>",title,
            "<global halign=center color=#000 size="..ftsize.." font=Regular>\n",message,"]",
            show_next,
            back,
        }
        minetest.show_formspec("singleplayer", "trifle_core:victory", table.concat(form))
    end
end


----------------------------------------------------------
--
-- trifle.do_failure(spec)
--
-- returns the do_failure() function
-- based on the provided spec table:
--  spec = {
--       title = "title",  The title is at the top
--       message = "message",  And the text below is shown below the title, 
--              keep in mind text can be colored <style color=colorstring> before the text in question.
--       ftsize  = Message Font size. Title is 32. Default is 16.
--       bgcolor = "color", --formats are #RGBA, #RGB, #RRGGBB, #RRGGBBAA or "red", "blue", "etc"
--      }
--
----------------------------------------------------------
function trifle.do_failure(spec)
    local title   = "Defeat!"
    local message    = "\n\nSorry about that, want to try again?"
    local bgcolor = "#BBBBBBFF"
    local ftsize  = 18
    if spec then --only do something if not nil
        if spec.title then title = spec.title end
        if spec.message then message  = spec.message end
        if spec.ftsize then ftsize  = spec.ftsize end
        if spec.bgcolor then bgcolor  = spec.bgcolor end
    end
    -- function to return
    return function()
        local set = trifle.current_level.setname
        local levelnum = trifle.current_level.level_number
        local form = {
            "formspec_version[3]",
            "size[8,10]",
            "position[0.5,0.5]",
            "anchor[0.5,0.5]",
            "no_prepend[]",
            "bgcolor["..bgcolor..";both;#333333A0]",
            "hypertext[0.5,0.2;7,7.8;;",
            "<global halign=center color=#222 size=32 font=Regular>",title,
            "<global halign=center color=#000 size="..ftsize.." font=Regular>\n",message,"]",
            "button_exit[4.5,8.5;2,1;retry;Retry]",
            "button_exit[1.5,8.5;2,1;back;Main Menu]",
        }
        minetest.show_formspec("singleplayer", "trifle_core:failure", table.concat(form))
    end
end