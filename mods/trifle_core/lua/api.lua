-----External Focused API-----

-------------------------------------------------------------
--
-- trifle.add_set(name_of_set, icon_texture_name)
--
-- Pretty straight forward, right?
-------------------------------------------------------------
function trifle.add_set(name_of_set, icon_texture_name)
    if not trifle.levels.name_of_set then
        trifle.levels[name_of_set] = {}
        trifle.levels[name_of_set].num = 0
        trifle.levels.num = trifle.levels.num+1
        trifle.levels[trifle.levels.num] = name_of_set
        trifle.levels[name_of_set].icon = icon_texture_name
    else
        minetest.log("Unable to register new trifle game set: "..name_of_set..". It already exists!")
    end
end

-------------------------------------------------------------
--
-- trifle.add_level(name_of_set, name_of_level, level_number, level_file)
--
-- see core.lua to learn about a level_def
-------------------------------------------------------------
function trifle.add_level(name_of_set, name_of_level, level_number, icon_texture_name, level_def)
    if not trifle.levels[name_of_set][level_number] then
        trifle.levels[name_of_set].num = trifle.levels[name_of_set].num + 1
        trifle.levels[name_of_set][level_number] = {}
        trifle.levels[name_of_set][level_number].name = name_of_level
        trifle.levels[name_of_set][level_number].icon = icon_texture_name
        trifle.levels[name_of_set][level_number].level = table.copy(level_def)
    else
        minetest.log("error", "Unable to register new "..name_of_set.." level number "..level_number..".\nIt already exists!")
    end
end

-------------------------------------------------------------
--
-- trifle.add_action(name,func)
--
-- func must be a function(action_def)
--
-- where action_def = {
--              action = string, --can safely ignore this, handled by trifle.core
--              delay = number,  --can safely ignore this, handled by trifle.core
--              round = number,  --can safely ignore this, handled by trifle.core
--
--              --and the rest of the table can be whatever you want it to have to make
--                your action work. for example:
--              custom1 = "fun",
--              num = 5,
--
--              --and so on
--          }
-------------------------------------------------------------
function trifle.add_action(name,func)
    if type(name) ~= "string" then minetest.log("error", "trifle_core:Invalid string entered for action registration") end
    if trifle.actions[name] ~= nil then minetest.log("error", "trifle_core:"..name.." is already registered as an action") end
    trifle.actions[name] = func
end
