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
            table.insert(r,"hypertext[2.3,"..((i-1)*1.8+0.4)..";0.4,1;;")
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
    if formname ~= "trifle_core:main_menu" then
        return
    end
    if fields.back then
        trifle.menu_set = nil
        minetest.show_formspec(player:get_player_name(), "trifle_core:main_menu", trifle.main_menu())
        return
    end
    --Loop through all fields
    for name,_ in pairs(fields) do
        if string.sub(name,1,3) == "set" then
            trifle.menu_set = tonumber(string.sub(name,4,-1))
            minetest.show_formspec(player:get_player_name(), "trifle_core:main_menu", trifle.main_menu())
        elseif string.sub(name,1,5) == "level" then
            if trifle.menu_set ~= nil then
                trifle.load_level(trifle.levels[trifle.menu_set], tonumber(string.sub(name,6,-1)))
            else
                --This should never happen but oh well:
                minetest.show_formspec(player:get_player_name(), "trifle_core:main_menu", trifle.main_menu())
            end
        end
    end
    --local setname = trifle.levels[trifle.levels.num]
    --trifle.load_level(setname, 1)
end

minetest.register_on_player_receive_fields(function(player, formname, fields) trifle.onRecieveFields(player, formname, fields) end)