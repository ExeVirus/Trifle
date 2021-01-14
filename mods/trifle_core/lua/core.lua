--Core.lua

trifle.levels = {}
trifle.levels.num = 0

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
    player_ref:set_physics_override({
        speed = 4,
        jump  = 0,
        gravity = 0,
        sneak = false,
        sneak_glitch = false,
        new_move = true,        
    })
    player_ref:set_pos({x=0,y=5,z=0})
    minetest.show_formspec(player_ref:get_player_name(), "trifle_core:main_menu", trifle.main_menu())
end

minetest.register_on_joinplayer(function(player_ref,_) trifle.onJoinPlayer(player_ref,_) end)

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
    local setname = trifle.levels[trifle.levels.num]
    trifle.load_level(setname, 1)
end

minetest.register_on_player_receive_fields(function(player, formname, fields) trifle.onRecieveFields(player, formname, fields) end)


trifle.current_level = {}


----------------------------------------------------------
--
-- trifle.load_level(level_def)
--
-- level_def  = {
--        size_x= integer, representing the "width"  of the playing board
--        size_y= integer, representing the "height" of the playing board
--        pos   = {x,y,z}, standard minetest position representing the top left corner of the map
--        data  = {
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
--        victory = "survive","get_to","destroy","population","custom",
--
--            Each of the options for victory represent different win conditions, 
--            and have variables that must be set inside the level def when used. For example, for "survive",
--            you must have: victory="survive", and a variable: round=<integer>. See below for the key:
--    
--            "survive"    -- Survive through round number
--                round=<integer>
--            "get_to"     -- Player must have a "life" node on point or points before the end of round number    
--                points = { {x,y,z}, {x,y,z} , ... } at least one, as many as you want
--                round  = <integer>
--            "destroy"    -- Player must defeat all enemy by round number
--                round  = <integer>
--            "population" -- Player must have at least pop number of life by the end of round number
--                round  = <integer>
--                pop    = <integer>
--            "custom"     -- You must define your own victory condition function called victory_function(), which is called at the end every round
--                victory_function=function(round_num)
--      failure = <integer>, --If your life drops below the integer value then you lose, if not set, the check is not performed: i.e. failure=nil
--        
--      pause_mode = "none","limited","toggle_increment","toggle_only","increment_only" --by default, the player may run a round with spacebar and toggle run/stop with "e" (toggle_increment)
--            none:                each round happens after round_time (see below)
--            toggle_only:       player may toggle run/stop with the "aux" ('e') button
--            increment_only:   player may increment the round num with "spacebar"
--            toggle_increment: player may both toggle and increment
--            limited:           player has limited number of pauses (toggles * 2)
--      pause_limit = <integer> --see "limited" pause_mode
--      start_paused = true/false, default true
--      round_time = <float> --in seconds, how low a round lasts in "run" mode
--
--        actions={                                              
--                    action_def1,
--                    action_def2,
--                    etc,
--                }
--             Actions will occur in the order they appear, one immediately after another, unless
--             either a delay=<float> value is set or round=<integer> value is set. These specify when
--             the next action should occur. delay is always since last action completed, and round will
--             be satisfied anytime current_level.current_round > round.
--             See trifle.process_actions to learn more (and find action_def)
--    }
----------------------------------------------------------
function trifle.load_level(setname, level_number)
    local new_level = trifle.levels[setname][level_number].level
    trifle.current_level = trifle.parse_map(new_level.map)
    
    --Parse the rest of the level settings
    --do_life function override
    if not new_level.do_life then
        trifle.current_level.do_life = trifle.do_life
    else
        trifle.current_level.do_life = new_level.do_life
    end
    
    trifle.paused = new_level.start_paused
    if not trifle.paused then trifle.paused = true end -- default true
    
    --Default starting values:
    trifle.current_level.setname          = setname
    trifle.current_level.level_number     = level_number
    trifle.current_level.current_action   = 1
    trifle.current_level.last_action_time = 0
    trifle.current_level.current_round    = 1
    trifle.clear_map()
    trifle.write_map(trifle.current_level)
    trifle.loaded = true --turn on globalstep
end

----------------------------------------------------------
--
-- trifle.parse_map(map_def)
--
-- Parses map_def and returns the resulting table, see 
-- trifle.load_level(level_def) for more information
-- see trifle.load_level()'s map defition
--
--
-- Note that, internally, each different node type
-- is stored as a power of ten. This is due to
-- how the game of life is played, looking at the surrounding
-- 8 tiles. If all eight are one node, we can be certain that
-- we can just take the sum and essential count the number of that
-- node nearby. This is a performance optimization. 
----------------------------------------------------------
function trifle.parse_map(map_def)
    local ret = {}
    ret.size_x = map_def.size_x
    ret.size_y = map_def.size_y
    ret.pos    = map_def.pos
    ret.data   = {}
    for i=0,ret.size_x+1,1 do
        ret.data[i] = {}
        for j=0,ret.size_y+1,1 do
            if i == 0 or j == 0 or i == ret.size_x+1 or j == ret.size_y+1 then --zero around the edges of map
                ret.data[i][j] = 0
            else
                local tile = string.sub(map_def.data[j],i,i)
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
                ret.data[i][j] = 10^math.random(0, 3)
                if math.random(0, 1) == 1 then
                    ret.data[i][j] = 0
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
    local new_data = table.copy(trifle.current_level.data)
    for i=1, level.size_x, 1 do
        for j=1, level.size_y, 1 do
            local count = (level.data[i-1][j-1] + level.data[i][j-1] +    level.data[i+1][j-1] +
                level.data[i-1][j] + level.data[i+1][j] + level.data[i-1][j+1] +
                level.data[i][j+1] + level.data[i+1][j+1])
            
            local life = (count % 10)
            if level.data[i][j] == 1 then
                if life == 2 or life == 3 then
                    new_data[i][j] = 1
                else
                    new_data[i][j] = 0
                end
            elseif level.data[i][j] == 0 then
                if life == 3 then
                    new_data[i][j] = 1
                end
            end
        end
    end
    trifle.current_level.data = new_data
    trifle.write_map(trifle.current_level)
    trifle.current_level.current_round = trifle.current_level.current_round + 1
    trifle.process_actions()
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
--     var1 = whatever           --These are custom to each action, see
--                               -- registrations.lua for built-in options
-- }
-- Increments the last_action_time once completed
-------------------------------------------------------------
function trifle.parse_action(action_def)
    if type(trifle.actions[action_def.action]) ~= "function" then 
        minetest.log("error", "Action Name: " .. action_def.action .. " from (set)"..
            trifle.current_level.setname.."-(level)"..trifle.current_level.level_number..
            " is not registered as a function")
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
-- trifle.globalstep(dtime)
--
-- This is the trifle globalstep function for handling player inputs
-- as well as running do_life at proper intervals (when not paused)
-- 
--
-- Note the local variable defaults here are required before this 
-- function is called
--
-- trifle.loaded is set by the main menu callback when the level is loaded
-- it is also set to false during level quit/shutdown.
-------------------------------------------------------------
local timer = 0
local tick  = 0
local down = {}
down.jump = false
trifle.loaded = false --
trifle.paused = true
function trifle.globalstep(dtime)
    if not trifle.loaded then return end --NO globalstep stuff when we're in the main menu
    
    timer = timer + dtime
    if timer < 0.01 then return end --20 fps
    tick = tick + timer
    timer = dtime
    --assume single player for now
    local player = minetest.get_player_by_name("singleplayer")
    if player then
        local controls = player:get_player_control()
        if controls.jump and not down.jump then
            down.jump = true
            trifle.paused = not trifle.paused
        elseif not controls.jump then
            down.jump = false
        end
    end
    if tick < 2 then return end --twice a second
    tick = timer
    if not trifle.paused then 
        trifle.do_life()
    end    
end

--Actually register the function
minetest.register_globalstep(function(dtime) trifle.globalstep(dtime) end)

-------------------------------------------------------------
--
-- trifle.pause()
--
-- Simply pauses any do_life occurances
-- 
-------------------------------------------------------------

-------------------------------------------------------------
--
-- trifle.unpause()
--
-- Unpauses do_life occurances (see trifle.globalstep())
-- Also will reset the counter for the current round so that
-- the full round time will occur before the next round happens.
-- 
-------------------------------------------------------------

-------------------------------------------------------------
--
-- trifle.quit()
--
-- Returns back to main menu formspec, by setting trifle.loaded = false
-- and tirfle.paused = true
-- 
-------------------------------------------------------------

