--Core.lua

trifle.levels = {}
trifle.levels.num = 0

minetest.register_on_joinplayer(
	function(player_ref, _)
		player_ref:set_physics_override({
			speed = 4,
			jump  = 0,
			gravity = 0,
			sneak = false,
			sneak_glitch = false,
			new_move = true,		
		})
		player_ref:set_pos({x=0,y=5,z=0})
		minetest.show_formspec(player_ref:get_player_name(), "trifle_core:main", trifle.main_formspec())
	end
)

minetest.register_item(":", {
	type = "none",
	wield_image = "transparent.png",
	range = 50,
	tool_capabilities = {
		full_punch_interval = 0.5,
	}
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "trifle_core:main" then
        return
    end
	local setname = trifle.levels[trifle.levels.num]
	trifle.load_level(trifle.levels[setname][2].level.map)
end)

trifle.current_level = {}

function trifle.load_level(map)
	--delete old level ?
	trifle.current_level.size_x = map.size_x
	trifle.current_level.size_y = map.size_y
	trifle.current_level.pos = map.pos
	trifle.current_level.data = {}
	for i=0,map.size_x+1,1 do
		trifle.current_level.data[i] = {}
		for j=0,map.size_y+1,1 do
			if i == 0 or j == 0 or i == map.size_x+1 or j == map.size_y+1 then --zero around the edges
				trifle.current_level.data[i][j] = 0
			else
				local tile = string.sub(map.data[j],i,i)
				if tile == "+" then --life
					trifle.current_level.data[i][j] = 1
				elseif tile == "#"  then --enemy
					trifle.current_level.data[i][j] = 2
				elseif tile == "0"  then --structure
					trifle.current_level.data[i][j] = 3
				elseif tile == "*" then --hint
					trifle.current_level.data[i][j] = 4
				elseif tile == "." then
					trifle.current_level.data[i][j] = 0
				else
					minetest.log("warning", "Map has undefined characters!")
				end
			end
		end
	end
	trifle.clear_map()
	trifle.write_map(trifle.current_level)
end

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

function trifle.write_map(map)
	for i=1,map.size_x,1 do
		for j=1,map.size_y,1 do
			local offset = {x=map.pos.x+i, y=map.pos.y, z=map.pos.z+j}
			local tile = map.data[i][j]
			if tile == 1 then --life
				minetest.set_node(offset, {name="trifle_core:life"})
			elseif tile == 2  then --enemy
				minetest.set_node(offset, {name="trifle_core:enemy"})
			elseif tile == 3  then --structure
				minetest.set_node(offset, {name="trifle_core:structure"})
			elseif tile == 4 then --hint
				minetest.set_node(offset, {name="trifle_core:hint"})
			elseif tile == 0 then
				minetest.set_node(offset, {name="air"})
			else
				minetest.log("warning", "Map has undefined characters!")
			end
			minetest.set_node({x=offset.x, y=-1, z=offset.z}, {name="trifle_core:tile"})
		end
	end
end

local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

function trifle.do_life()
	local level = trifle.current_level
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

