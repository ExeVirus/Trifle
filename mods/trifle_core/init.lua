--  _____      _  __ _          ___               
-- /__   \_ __(_)/ _| | ___    / __\___  _ __ ___ 
--   / /\/ '__| | |_| |/ _ \  / /  / _ \| '__/ _ \
--  / /  | |  | |  _| |  __/ / /__| (_) | | |  __/
--  \/   |_|  |_|_| |_|\___| \____/\___/|_|  \___|
--                                               
--
--              Core Trifle Mod and API
--					By ExeVirus
--

-----------------------------------------------------
--
--                    Overview
--
--   Other mods should depend on this one, and all mods 
--   Should only include function calls defined by this 
--   mod. Notable ones are:
--
--   trifle.add_set(name_of_set, icon_texture_name)
--
--         This function registers a new selectable
--         game for a player to choose, like "tutorial"
--         and "Demo".
--
--   trifle.add_level(name_of_set, name_of_level, level_number, level_file)
--
--   level_file is a special trifle lua file. For example: "tutorial_1.lua"
--   these should be stored in a "levels" folder in your mod, they will
--   describe the starting playing field, the starting formspec, win condition,
--   etc.
--
--
--   See the trifle wiki at https://github.com/ExeVirus/trifle/ for more information
--
--
local mp = minetest.get_modpath("trifle_core")
trifle = {} --Global Trifle Namespace

--Node registrations
dofile(mp.."/lua/registrations.lua")

--Sounds for game
dofile(mp.."/lua/sounds.lua")

--Gui for everything
dofile(mp.."/lua/gui.lua")

--Core Engine, Game Loop, settings overrides, etc.
dofile(mp.."/lua/core.lua")

--Modder API
dofile(mp.."/lua/api.lua")



