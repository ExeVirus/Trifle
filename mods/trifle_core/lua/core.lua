--Core.lua

trifle.levels = {}
trifle.levels.num = 0
trifle.hud = {}
trifle.paused  = false

--Utility function for core.lua, performs a deep copy of a table
--so we don't overwrite values....
local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

----------------------------------------------------------
--
--   trifle.onJoinPlayer(player_ref, _)
--
-- player_ref: player object that just joined
-- 
-- Sets up player welcome formspec, physics, and position
----------------------------------------------------------
function trifle.onJoinPlayer(player_ref, _)
    trifle.load_hud(player_ref)
    trifle.clear_map()
    trifle.ready_physics()
    minetest.show_formspec(player_ref:get_player_name(), "trifle_core:main_menu", trifle.main_menu())
    trifle.ready_physics()
end

minetest.register_on_joinplayer(function(player_ref,_) trifle.onJoinPlayer(player_ref,_) end)

trifle.current_level = {}

------------------
--
-- function trifle.ready_physics()
--
-- For some reason, minetest missing the set_player_physics call a LOT
--
-- so we are going to do it multiple times with a function 
-----------------------
function trifle.ready_physics()
    local player = minetest.get_player_by_name("singleplayer")
    player:set_physics_override({
        speed = 4,
        jump  = 0,
        gravity = 0,
        sneak = false,
        sneak_glitch = false,
        new_move = true,
    })
    player:set_velocity({x=0,y=0,z=0})
    player:set_pos({x=0,y=5,z=0})
end

----------------------------------------------------------
--
-- trifle.load_level(level_def)
--
-- level_def  = { --note things labeled as "REQ" in front are REQUIRED, everything else is OPTIONAL
--REQ     size_x= integer, representing the "width"  of the playing board
--REQ     size_y= integer, representing the "height" of the playing board
--REQ     pos   = {x,y,z}, standard minetest position representing the top left corner of the map
--REQ     data  = {
--                  "............",  this table represents the starting map layout,
--                  "............",  each string is one row (size_x) and there are size_y rows
--                  "............",  failure to fill out correctly results in an error.
--                },
--                      data table key:
--                          . => empty spot (air node)
--                          + => life node
--                          # => enemy node
--                          0 => structure node
--                          * => hint node                
--
--        do_life = function(),  Implement your own rulesets for the level!
--
--REQ     victory = "survive","get_to","destroy","population","custom"
--
--            Each of the options for victory represent different win conditions, 
--            and have variables that must be set inside the level def when used. For example, for "survive",
--            you must have: victory="survive", and a variable: round=<integer>. To get a better understanding of 
--            what victory is, see each victory's default victory function. survive's is trifle.survive_victory_function()
--            See below for the key:
--    
--            "survive"    -- Survive through round number
--                final_round=<integer>
--            "get_to"     -- Player must have a "life" node on point or points before the end of round number    
--                get_to_points = { {x,z}, {x,z} , ... } at least one, as many as you want
--                final_round  = <integer>
--            "destroy"    -- Player must defeat all enemy by round number
--                final_round  = <integer>
--            "population" -- Player must have at least pop number of life by the end of round number
--                final_round  = <integer>
--                pop    = <integer>
--            "custom"     -- You must define your own victory condition function called victory_function(), which is called at the end every round
--                custom_victory = function()
--                custom_vars = {} custom vars can be a user defined table of variables or a single variable, whatever you need. It'll be stored
--                                 inside trifle.current_level.custom_vars
--       failure = "life_limit", "enemy_limit", "enemy_get_to" --Note that custom is not included here, please use the victory function for custom failure modes
--                Very similar to victory, there are three possible built-in failure modes. If you want a custom failure mode, work it into the victory function.
--            "life_limit" -- minimum number of lives you can have at any point
--               life_limit = <integer>
--            "enemy_limit" -- maximum number of lives the enemy can have at any point
--               enemy_limit = <integer>
--            "enemy_get_to" -- you lose if there is an enemy on any position specified in enemy_points
--               enemy_points = { {x,z},{x,z} , ... } at least one, as many as you want
--            "custom"-- You must define your own failure condition function called failure_function(), which is called at the end every round, *after* the victory_function
--               ---custom vars is the same variable used here as victory_function's custom, so share:)
--
--      do_victory = function(),  Implement your own formspec and sounds and stuff for showing the user victory! 
--              --note both the default trifle.do_victory and trifle.do_failure are found in gui.lua. Not this file
--            OR if do_victory is a table, the default show_victory function is used with this text.
--            do_victory = {
--                  title   = "title",  The title is at the top
--                  message = "message",  And the text below is shown below the title, 
--                                  keep in mind text can be colored <style color=colorstring> before the text in question.
--                  ftsize  = Message Font size. Title is 32. Default is 16.
--                  bgcolor = "color", --formats are #RGBA, #RGB, #RRGGBB, #RRGGBBAA or "red", "blue", "etc"
--                },
--
--      do_failure = function(),  Implement your own formspec and sounds and stuff for showing the user defeat!
--          OR if do_failure is a table, the default failure function is used with this text.
--            do_failure = {
--                  title   = "title",  The title is at the top
--                  message = "message",  And the text below is shown below the title, 
--                                  keep in mind text can be colored <style color=colorstring> before the text in question.
--                  ftsize  = Message Font size. Title is 32. Default is 16.
--                  bgcolor = "color", --formats are #RGBA, #RGB, #RRGGBB, #RRGGBBAA or "red", "blue", "etc"
--                },
--
--      pause_mode = "none","limited","toggle_increment","toggle_only","increment_only" --by default, the player may run a round with spacebar and toggle run/stop with "e" (toggle_increment)
--            none:             each round happens after 'round_time (see below), the player will typically unpause to start the game
--            toggle_increment: player may both toggle and increment
--            limited:          player has limited number of pauses, only counts when "pause" happens, not unpause. No incrementing.
-- 
--      pause_limit = <integer>, --see "limited" pause_mode above
--      start_paused = true/false, default true
--      round_time = <float>, --in seconds, how low a round lasts in "run" mode, default 0.5
--
--      intro = {                --An intro is an formspec shown to the user when loading up the level
--                title   = "title",  The title is at the top
--                message = "message",  And the text below is shown below the title, 
--                                  keep in mind text can be colored <style color=colorstring> before the text in question.
--                ftsize  = Message Font size. Title is 32. Default is 16.
--                bgcolor = "color", --formats are #RGBA, #RGB, #RRGGBB, #RRGGBBAA or "red", "blue", "etc"
--              },
--
--      actions={
--                  action_def1, --learn more about action_defs in trifle.parse_action() below
--                  action_def2,
--                  etc,
--              },
--             Actions will occur in the order they appear, one immediately after another, unless
--             either a delay=<float> value is set or round=<integer> value is set. These specify when
--             the next action should occur. delay is always since last action completed, and round will
--             be satisfied anytime current_level.current_round > round.
--             See trifle.process_actions to learn more (and find action_def)
--
--    } --end of level_def description
----------------------------------------------------------
function trifle.load_level(setname, level_number)
    local new_level = trifle.levels[setname][level_number].level
    
    --parse the level_def map variables
    trifle.current_level.setname          = setname      -- these two lines only
    trifle.current_level.level_number     = level_number -- exist for the warn and quit below....
    if new_level ~= nil then
        trifle.current_level = trifle.parse_map(new_level)
    else trifle.warn_and_quit("No .level specified in level_def.") return end
    
    --Default starting values:
    trifle.current_level.setname          = setname
    trifle.current_level.level_number     = level_number
    trifle.current_level.icon             = trifle.levels[setname][level_number].icon or trifle.levels[setname].icon 
    trifle.current_level.current_action   = 1
    trifle.current_level.last_action_time = 0
    trifle.current_level.current_round    = 1
    
    --For hud updates:
    local player = minetest.get_player_by_name("singleplayer")
    player:hud_change(trifle.hud.round, "text", "1")
    
    --victory mode
    if new_level.victory == nil then trifle.warn_and_quit("No (or invalid) .victory specified in level_def.") return end
    trifle.current_level.victory = new_level.victory
    if not trifle.set_victory(new_level) then return end
    
    --failure mode
    if new_level.failure ~= nil then 
        if not trifle.set_failure(level_def) then return false end
    else --not set, so do nothing:
        trifle.current_level.failure_function = function() return end 
    end
    
    --do_life function override
    if new_level.do_life == nil then trifle.current_level.do_life = trifle.do_life else
    trifle.current_level.do_life = new_level.do_life end
    
    --do_victory function override
    if not new_level.do_victory then trifle.current_level.do_victory = trifle.do_victory()
    elseif type(new_level.do_victory) == "function" then trifle.current_level.do_victory = new_level.do_victory()
    elseif type(new_level.do_victory) == "table" then trifle.current_level.do_victory = trifle.do_victory(new_level.do_victory)
    else trifle.warn_and_quit("No .do_victory is not a function or table") end
    
    --do_failure function override
    if new_level.do_failure == nil then trifle.current_level.do_failure = trifle.do_failure()
    elseif type(new_level.do_failure) == "function" then trifle.current_level.do_failure = new_level.do_failure()
    elseif type(new_level.do_failure) == "table" then trifle.current_level.do_failure = trifle.do_failure(new_level.do_failure)
    else trifle.warn_and_quit("No .do_failure is not a function or table") end
    
    --start paused?
    if new_level.start_paused == nil then trifle.running = false else -- default true
    trifle.running = new_level.start_paused end
    
    --time for each round
    if new_level.round_time == nil then trifle.current_level.round_time = 0.5 else
    trifle.current_level.round_time = new_level.round_time end
    
    --limited number of pauses
    if new_level.pause_limit ~= nil then trifle.current_level.pause_limit = new_level.pause_limit end
    
    --pause mode
    if new_level.pause_mode == nil then trifle.current_level.pause_mode = "toggle_increment"
    else if not trifle.set_pause_mode(new_level.pause_mode) then return false end end
    
    --actions table
    if new_level.actions ~= nil then trifle.current_level.actions = new_level.actions end
    trifle.ready_physics()
    trifle.clear_map()
    trifle.write_map(trifle.current_level)
    if new_level.intro then
        if trifle.intro(new_level.intro) == false then return end -- do the intro, we'll be loaded after closing that formspec
    else
        trifle.loaded = true  -- turn on globalstep now, since there's no intro
    end
end

----------------------------------------------------------
--
-- trifle.parse_map(level_def)
--
-- Parses level_def and returns the resulting table, see 
-- trifle.load_level(level_def) for more information
-- see trifle.load_level()
--
--
-- Note that, internally, each different node type
-- is stored as a power of ten. This is due to
-- how the game of life is played, looking at the surrounding
-- 8 tiles. If all eight are one node, we can be certain that
-- we can just take the sum and essential count the number of that
-- node nearby. This is a performance optimization. 
----------------------------------------------------------
function trifle.parse_map(level_def)
    local ret = {}
    ret.size_x = level_def.size_x
    ret.size_y = level_def.size_y
    ret.pos    = level_def.pos
    ret.data   = {}
    for i=0,ret.size_x+1,1 do
        ret.data[i] = {}
        for j=0,ret.size_y+1,1 do
            if i == 0 or j == 0 or i == ret.size_x+1 or j == ret.size_y+1 then --zero around the edges of map
                ret.data[i][j] = 0
            else
                local tile = string.sub(level_def.data[j],i,i)
                if tile == "+" then --life
                    ret.data[i][j] = 1
                elseif tile == "#"  then --enemy
                    ret.data[i][j] = 10
                elseif tile == "0"  then --structure
                    ret.data[i][j] = 100
                elseif tile == "*" then --hint
                    ret.data[i][j] = 1000
                elseif tile == "." then
                    ret.data[i][j] = 0
                else
                    minetest.log("warning", "Level data has undefined characters!")
                end
            end
        end
    end
    return ret
end


-------------------------------------------------------------
--
-- trifle.clear_map()
--
-- clears out the map, which can't be larger than 100x100
-- feel free to overwrite this with larger values :thumbsup:
-------------------------------------------------------------
function trifle.clear_map()
    for i=-50,50,1 do
        for j=-50,50,1 do
            local offset  = {x=i, y=0,  z=j}
            local offset2 = {x=i, y=-1, z=j}
            minetest.set_node(offset, {name="air"})
            minetest.set_node(offset2, {name="air"})
        end
    end
end

-------------------------------------------------------------
--
-- trifle.write_map(parsed_map)
--
-- write the parsed_map (from parse_map) to world
-------------------------------------------------------------
function trifle.write_map(parsed_map)
    for i=1,parsed_map.size_x,1 do
        for j=1,parsed_map.size_y,1 do
            local offset = {x=parsed_map.pos.x+i, y=parsed_map.pos.y, z=parsed_map.pos.z+j}
            local tile = parsed_map.data[i][j]
            if     tile == 1 then --life
                minetest.set_node(offset, {name="trifle_core:life"})
            elseif tile == 10  then --enemy
                minetest.set_node(offset, {name="trifle_core:enemy"})
            elseif tile == 100  then --structure
                minetest.set_node(offset, {name="trifle_core:structure"})
            elseif tile == 1000 then --hint
                minetest.set_node(offset, {name="trifle_core:hint"})
            elseif tile == 0 then
                minetest.set_node(offset, {name="air"})
            else
                minetest.log("warning", "Parsed_map is invalid, unknown node values!")
            end
            minetest.set_node({x=offset.x, y=-1, z=offset.z}, {name="trifle_core:tile"})
        end
    end
end

-------------------------------------------------------------
--
-- trifle.do_life()
--
-- Reads the current level and performs the game of life "round"
-- overwrite this function to change the default ruleset, though
-- the reccomended method is to change this function on a per-level
-- basis
--
-- Note that this function calls the current level's victory_function()
-- as well as its process_actions() functions at the end, you will want 
-- to do the same in your custom do_life() function
-------------------------------------------------------------
function trifle.do_life()
    local level    = trifle.current_level
    local new_data = table.copy(level.data)
    for i=1, level.size_x, 1 do
        for j=1, level.size_y, 1 do
            local count = (level.data[i-1][j-1] + level.data[i][j-1] + level.data[i+1][j-1] +
                level.data[i-1][j] + level.data[i+1][j] + level.data[i-1][j+1] +
                level.data[i][j+1] + level.data[i+1][j+1])
            
            local life   = (count % 10)
            local enemy  = math.floor((count / 10)  % 10)
            local struct = math.floor((count / 100) % 10)
            
            if level.data[i][j] == 1 then
                if enemy > 0 then
                    new_data[i][j] = 0
                elseif life == 2 or life == 3 then
                    new_data[i][j] = 1
                else
                    new_data[i][j] = 0
                end
            elseif level.data[i][j] == 10 then
                if life > 0 then
                    new_data[i][j] = 0
                elseif enemy == 2 or enemy == 3 then
                    new_data[i][j] = 10
                else
                    new_data[i][j] = 0
                end
            elseif level.data[i][j] == 0 or level.data[i][j] == 1000 then --hints are also empty
                if life + enemy == 3 then
                    if life > enemy then
                        new_data[i][j] = 1
                    else
                        new_data[i][j] = 10
                    end
                end
            end
        end
    end
    trifle.current_level.data = new_data
    trifle.write_map(trifle.current_level)
    trifle.current_level.current_round = trifle.current_level.current_round + 1
    minetest.get_player_by_name("singleplayer"):hud_change(trifle.hud.round, "text", trifle.current_level.current_round)
    trifle.process_actions()
    if trifle.current_level.victory_function() == true then --performs win checks
        trifle.current_level.do_victory()
    end
    if trifle.current_level.failure_function() == false then
        trifle.current_level.do_failure()
    end
end

-------------------------------------------------------------
--
-- trifle.process_actions()
--
-- Reads the current_level.actions table, using the current_level.current_action
-- value as a lookup value. Will check if conditions have been met and then send
-- it to trifle.parse_action() to be further parsed
--
-------------------------------------------------------------
function trifle.process_actions()
    if not trifle.current_level.actions then return end --no actions defined
    local action = trifle.current_level.actions[trifle.current_level.current_action]
    if not action then return end --No more actions defined, or no actions defined
    local delay = action.delay * 1000000 --microseconds
    local round = action.round
    if delay then
        if delay + trifle.current_level.last_action_time < minetest.get_us_time() then
             return --Stop, delay time has not passed
        end
    end
    if round then
        if round >= trifle.current_level.current_round then
            return --Stop, we haven't gotten to that round yet
        end
    end
    --Delay and round checks passed
    trifle.parse_action(action) 
    trifle.current_level.current_action = trifle.current_level.current_action + 1
    trifle.process_actions() -- recursively go though the action list
end

-------------------------------------------------------------
--
-- trifle.parse_action(action_def) 
--
-- Parses and executes the provided action
-- Add new action types with trifle.add_action_type(typename,parse_function), see api.lua
-- action_def = {
--     action = "action name"    -- list of built-in options: See registrations.lua
--     delay  = <decimal number> -- in seconds
--     round  = <integer>        -- 
--     var1   = whatever         --These are custom to each action, see
--     var2,etc                  --registrations.lua for built-in options
-- }
-- Increments the last_action_time once completed
-------------------------------------------------------------
function trifle.parse_action(action_def)
    if type(trifle.actions[action_def.action]) ~= "function" then 
        minetest.log("error", "Action Name: " .. action_def.action .. " from (set)"..
            trifle.current_level.setname.."-(level)"..trifle.current_level.level_number..
            " does not have a valid function!")
        trifle.last_action_time = minetest.get_us_time() --No need to stop working, let's soldier on
        return
    end
    --execute the specific action for this action type
    trifle.actions[action_def.action](action_def)
    --reset the last_time counter
    trifle.last_action_time = minetest.get_us_time()
end

-------------------------------------------------------------
--
-- trifle.set_victory(level_def) 
--
-- Parses and sets up the victory conditions for the level
-- returns false on failure and warns the user (and quits)
-- 
-------------------------------------------------------------
function trifle.set_victory(level_def)
    local v = trifle.current_level.victory
    if     v == "survive" then
    
        --check final_round is valid:
        if level_def.final_round == nil or type(level_def.final_round) ~= "number" then 
            trifle.warn_and_quit("level_def.final_round must be set for 'survive' victory type.") return false end
        trifle.current_level.final_round = level_def.final_round
        
        --Set victory function
        trifle.current_level.victory_function = trifle.survive_victory_function
        
    elseif v == "get_to" then
    
        --check final_round is valid:
        if level_def.final_round == nil or type(level_def.final_round) ~= "number" then 
            trifle.warn_and_quit("level_def.final_round must be set for 'get_to' victory type.") return false end
        trifle.current_level.final_round = level_def.final_round
        
        --check get_to_points is valid:
        if level_def.get_to_points == nil or type(level_def.get_to_points) ~= "table" then 
            trifle.warn_and_quit("level_def.get_to_points must be set as a table for 'get_to' victory type.") return false end
        trifle.current_level.get_to_points = level_def.get_to_points

        --Set victory function
        trifle.current_level.victory_function = trifle.get_to_victory_function
        
    elseif v == "destroy" then
    
        --check final_round is valid:
        if level_def.final_round == nil or type(level_def.final_round) ~= "number" then 
            trifle.warn_and_quit("level_def.final_round must be set for 'destroy' victory type.") return false end
        trifle.current_level.final_round = level_def.final_round
        
        --Set victory function
        trifle.current_level.victory_function = trifle.destroy_victory_function
    
    elseif v == "population" then
    
        --check final_round is valid:
        if level_def.final_round == nil or type(level_def.final_round) ~= "number" then 
            trifle.warn_and_quit("level_def.final_round must be set for 'population' victory type.") return false end
        trifle.current_level.final_round = level_def.final_round
        
        --check pop is valid:
        if level_def.pop == nil or type(level_def.pop) ~= "number" then 
            trifle.warn_and_quit("level_def.pop must be set for 'population' victory type.") return false end
        trifle.current_level.pop = level_def.pop
        
        --Set victory function
        trifle.current_level.victory_function = trifle.population_victory_function
    
    elseif v == "custom" then
        --check that custom function is valid
        if level_def.custom_victory == nil or type(level_def.custom_victory) ~= "function" then 
            trifle.warn_and_quit("level_def.custom_victory (function) must be set for 'custom' victory type.") return false end
        trifle.current_level.custom_victory = level_def.custom_victory
        
        --check for custom vars
        if level_def.custom_vars ~= nil then trifle.current_level.custom_vars = level_def.custom_vars end
        
        --Set victory function
        trifle.current_level.victory_function = level_def.custom_victory
    else --No matches
        trifle.warn_and_quit("level_def.victory: '"..trifle.current_level.victory.."' is not a recognized type")
        return false
    end
    return true
end

-------------------------------------------------------------
--
-- trifle.survive_victory_function() 
--
-- Default victory function for the "survive" level victory type
-- Checks if there is *any* life (blue) on the board when current_round
-- is larger than the level_def.round value. For example, to 
-- check for win or loss on round 5, we would set the 
-- level_def.round = 5.
-- 
-- 
-------------------------------------------------------------
function trifle.survive_victory_function()

end

-------------------------------------------------------------
--
-- trifle.get_to_victory_function() 
--
-- 
-------------------------------------------------------------
function trifle.get_to_victory_function()

end

-------------------------------------------------------------
--
-- trifle.destroy_victory_function() 
--
-- 
-------------------------------------------------------------
function trifle.destroy_victory_function()

end

-------------------------------------------------------------
--
-- trifle.population_victory_function() 
--
-- 
-------------------------------------------------------------
function trifle.population_victory_function()

end

-------------------------------------------------------------
--
-- trifle.set_failure(level_def) 
--
-- Parses and sets up the failure conditions for the level
-- returns false on failure to setup and warns the user (and quits)
-- 
-------------------------------------------------------------
function trifle.set_failure(level_def)
    if level_def.failure     == "life_limit" then
        trifle.current_level.failure = "life_limit"
    
        --check life_limit is valid:
        if level_def.life_limit == nil or type(level_def.life_limit) ~= "number" then 
            trifle.warn_and_quit("level_def.life_limit must be set for 'life_limit' failure type.") return false end
        trifle.current_level.life_limit = level_def.life_limit
        
        --set failure_function:
        trifle.current_level.failure_function = trifle.life_limit_failure_function
        
    elseif level_def.failure == "enemy_limit" then
        trifle.current_level.failure = "enemy_limit"
        
        --check enemy_limit is valid:
        if level_def.enemy_limit == nil or type(level_def.enemy_limit) ~= "number" then 
            trifle.warn_and_quit("level_def.enemy_limit must be set for 'enemy_limit' failure type.") return false end
        trifle.current_level.enemy_limit = level_def.enemy_limit
        
        --set failure_function:
        trifle.current_level.failure_function = trifle.enemy_limit_failure_function
        
    elseif level_def.failure == "enemy_get_to" then
        trifle.current_level.failure = "enemy_get_to"
    
        --check enemy_points is valid:
        if level_def.enemy_points == nil or type(level_def.enemy_points) ~= "table" then 
            trifle.warn_and_quit("level_def.enemy_points (table) must be set for 'enemy_get_to' failure type.") return false end
        trifle.current_level.enemy_points = level_def.enemy_points
        
        --set failure_function:
        trifle.current_level.failure_function = trifle.enemy_points_failure_function
    elseif level_def.failure == "custom" then
        trifle.current_level.failure = "custom"
        
        --check that custom function is valid
        if level_def.custom_failure == nil or type(level_def.custom_failure) ~= "function" then 
            trifle.warn_and_quit("level_def.custom_failure (function) must be set for 'custom' failure type.") return false end
        trifle.current_level.custom_failure = level_def.custom_failure
        
        --check for custom vars
        if level_def.custom_vars ~= nil then trifle.current_level.custom_vars = level_def.custom_vars end
        
        --Set victory function
        trifle.current_level.failure_function = level_def.custom_failure
        
    else
        trifle.warn_and_quit("level_def.failure: '"..level_def.failure.."' is not a recognized type")
        return false
    end
end

-------------------------------------------------------------
--
-- trifle.life_limit_failure_function() 
--
-- 
-------------------------------------------------------------
function trifle.life_limit_failure_function()

end

-------------------------------------------------------------
--
-- trifle.enemy_limit_failure_function() 
--
-- 
-------------------------------------------------------------
function trifle.enemy_limit_failure_function()

end

-------------------------------------------------------------
--
-- trifle.enemy_points_failure_function() 
--
-- 
-------------------------------------------------------------
function trifle.enemy_points_failure_function()

end


-------------------------------------------------------------
--
-- trifle.set_pause_mode(mode) 
--    pause_mode = "none","limited","toggle_increment","toggle_only","increment_only" --by default, the player may run a round with spacebar and toggle run/stop with "e" (toggle_increment)
--       none:             each round happens after 'round_time (see below), the player will typically unpause to start the game
--       toggle_increment: player may both toggle and increment
--       limited:          player has limited number of pauses, only counts when "pause" happens, not unpause. No incrementing.
-- 
-------------------------------------------------------------
function trifle.set_pause_mode(mode)
    if type(mode) ~= "string" then trifle.warn_and_quit("level_def.pause_mode is not a valid string.") return false end
    if mode == "none" then
        trifle.current_level.pause_mode = "none"
    elseif mode == "toggle_increment" then
        trifle.current_level.pause_mode = "toggle_increment"
    elseif mode == "limited" then
        trifle.current_level.pause_mode = "limited"
    else
        trifle.warn_and_quit("level_def.pause_mode: '"..mode.."' is not recognized.")
    end 
end

-------------------------------------------------------------
--
-- trifle.warn_and_quit(warning)
--
-- 1. outputs a warning to minetest's log
-- 2. Shows a formspec to the user that shows the problem, 
--     user can choose to go to main menu or the formspec times out after 12 seconds
-------------------------------------------------------------
trifle.done_warning = false
function trifle.warn_and_quit(warning)
    local warn_string = {
        "Warning from trifle_core:\n",
        "In set-'"..trifle.current_level.setname.."', level-'"..trifle.current_level.level_number.."':\n",
        warning,
    }
    minetest.log("warning", table.concat(warn_string))
    minetest.chat_send_all(minetest.get_color_escape_sequence("red") .. table.concat(warn_string))
end

-------------------------------------------------------------
--
-- trifle.globalstep(dtime)
--
-- This is the trifle globalstep function for handling player inputs
-- as well as running do_life at proper intervals (when not paused), and
-- checking actions to be run that might have time-based requirements
--
-- Note the local variable defaults here are required before this 
-- function is called
--
-- trifle.loaded is set by the main menu callback when the level is loaded
-- it is also set to false during level quit/shutdown.
-------------------------------------------------------------
local timer = 0
local down = {}
down.jump = false
down.aux1 = false
trifle.loaded = false -- used by main_menu and trifle.quit()
trifle.running = false -- start stopped
function trifle.globalstep(dtime)
    if not trifle.loaded then return end --No other globalstep stuff when we're in the main menu
    
    trifle.process_actions(dtime)  -- for time-based actions checks
    
    if trifle.paused then return end -- for waiting on formspecs from actions and other such nonsense
    
    timer = dtime + timer
    --assume single player for now
    local player = minetest.get_player_by_name("singleplayer")
    if player then
        local controls = player:get_player_control()
        if controls.jump and not down.jump then
            down.jump = true
            trifle.current_level.do_life()
        elseif not controls.jump then
            down.jump = false
        end
        if controls.aux1 and not down.aux1 then
            down.aux1 = true
            if trifle.running then 
                trifle.stop()
            else    
                trifle.run()
            end
        elseif not controls.aux1 then
            down.aux1 = false
        end
    end
    if timer < trifle.current_level.round_time then return end --twice a second
    timer = dtime
    if trifle.running then 
        trifle.do_life()
    end
end

--Actually register the function
minetest.register_globalstep(function(dtime) trifle.globalstep(dtime) end)

-------------------------------------------------------------
--
-- trifle.stop()
--
-- Simply pauses any do_life occurances
-- 
-------------------------------------------------------------
function trifle.stop()
    trifle.running = false
end

-------------------------------------------------------------
--
-- trifle.run()
--
-- Unpauses do_life occurances (see trifle.globalstep())
-- Also will reset the counter for the current round so that
-- the full round time will occur before the next round increments
-- 
-------------------------------------------------------------
function trifle.run()
    trifle.running = true
    timer = 0
end

-------------------------------------------------------------
--
-- trifle.quit()
--
-- Returns back to main menu formspec, by setting trifle.loaded = false
-- and trifle.paused = true, this disables globalstep processing
-- 
-------------------------------------------------------------
function trifle.quit()
    trifle.loaded = false
    trifle.paused = true
    trifle.clear_map()
    minetest.show_formspec("singleplayer", "trifle_core:main_menu", trifle.main_menu())
end
