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
	trifle.load_level(trifle.levels[setname][2].level.map)
end

minetest.register_on_player_receive_fields(function(player, formname, fields) trifle.onRecieveFields(player, formname, fields) end)


trifle.current_level = {}


----------------------------------------------------------
--
-- trifle.load_level(level_def)
--
-- level_def  = {
-- 		size_x=integer, representing the "width"  of the playing board
--		size_y=integer, representing the "height" of the playing board
--     	pos={x,y,z}, standard minetest position representing the top left corner of the map
--		data={
--				"............",     this table represents the starting map layout,
--				"............",     each string is one row (size_x) and there are size_y rows
--				"............",     failure to fill out correctly results in an error.
--			 },
--							data table key:
--								. => empty spot (air node)
--								+ => life node
--					          	# => enemy node
--								0 => structure node
--								* => hint node
--		events= {
--					{action="play_sound", sound="start", volume=val},
--					{action="alert", text="Game has Begun!"},
--					{action="spawn", delay=3.5, map={ map_def }}, map_def is the same information 
--			    }   											as the first four parts of a level_def
--              There are many other actions not documented here, see "parse_action(action_def)"
--
--		do_life = function(),  Implement your own rulesets for the level!
--
--		victory = "survive","get_to","destroy","population","custom"
--
--		    Each of the options for victory represent different win conditions, 
--		    and have variables that must be set inside the level def when used. For example, for "survive",
--			you must have: victory="survive", and a variable: round=<integer>. See below for the key:
--	
--			"survive"    -- Survive through round number
--				round=<integer>
--	        "get_to"     -- Player must have a "life" node on point or points before the end of round number	
--				points = { {x,y,z}, {x,y,z} , ... } at least one, as many as you want
--	            round  = <integer>
--			"destroy"    -- Player must defeat all enemy by round number
--				round  = <integer>
--			"population" -- Player must have at least pop number of life by the end of round number
--				round  = <integer>
--				pop    = <integer>
--      
--		
--	}
----------------------------------------------------------
function trifle.load_level(level_def)
	--delete old level ?
	trifle.current_level = trifle.parse_map(level_def)
	if not level_def.do_life then
		trifle.current_level.do_life = trifle.do_life
	end
	trifle.clear_map()
	trifle.write_map(trifle.current_level)
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
-- overwrite this function to create your own rulesets, or be
-------------------------------------------------------------
function trifle.do_life()
	local level    = trifle.current_level
	local new_data = copy(trifle.current_level.data,nil)
	local count = 0
	for i=1, level.size_x, 1 do
		for j=1, level.size_y, 1 do
			count = 0
			if (level.data[i-1][j-1] == 1) then count = count + 1 end
			if (level.data[i]  [j-1] == 1) then count = count + 1 end
			if (level.data[i+1][j-1] == 1) then count = count + 1 end
			if (level.data[i-1][j]   == 1) then count = count + 1 end
			if (level.data[i+1][j]   == 1) then count = count + 1 end
			if (level.data[i-1][j+1] == 1) then count = count + 1 end
			if (level.data[i]  [j+1] == 1) then count = count + 1 end
			if (level.data[i+1][j+1] == 1) then count = count + 1 end
			if level.data[i][j] == 1 then
				if count == 2 or count == 3 then
					new_data[i][j] = 1
				else
					new_data[i][j] = 0
				end
			elseif level.data[i][j] == 0 then
				if count == 3 then
					new_data[i][j] = 1
				end
			end
		end
	end
	trifle.current_level.data = new_data
	trifle.write_map(trifle.current_level)
end

local timer = 0
local tick  = 0
local down = {}
down.jump = false
trifle.paused = true
minetest.register_globalstep(function(dtime)
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
)

