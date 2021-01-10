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
	trifle.load_level(trifle.levels[setname][1].level.map)
end)

function trifle.load_level(map)
	--delete old level ?
	for i=1,map.size_x,1 do
		for j=1,map.size_y,1 do
			local tile = string.sub(map.data[j],i,i)
			local offset = {x=map.pos.x+j, y=map.pos.y, z=map.pos.z+i}
			if tile == "+" then --life
				minetest.set_node(offset, {name="trifle_core:life"})
			elseif tile == "#"  then --enemy
				minetest.set_node(offset, {name="trifle_core:enemy"})
			elseif tile == "0"  then --structure
				minetest.set_node(offset, {name="trifle_core:structure"})
			elseif tile == "*" then --hint
				minetest.set_node(offset, {name="trifle_core:hint"})
			elseif tile == "." then
				minetest.set_node(offset, {name="air"})
			else
				minetest.log("warning", "Map has undefined characters!")
			end
			minetest.set_node({x=offset.x, y=-1, offset.z}, {name="trifle_core:tile"})
		end
	end
end

local timer = 0
local down = {}
down.jump = false
down.sneak = false
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 0.01 then return end --20 fps
	
	timer = dtime
	--assume single player for now
	local player = minetest.get_player_by_name("singleplayer")
	if player then
		local controls = player:get_player_control()
		if controls.jump and not down.jump then
			down.jump = true
			minetest.chat_send_all("Spacebar")
		elseif not controls.jump then
			down.jump = false
		end
		if controls.sneak and not down.sneak then
			down.sneak = true
			minetest.chat_send_all("Sneak")
		elseif not controls.sneak then
			down.sneak = false
		end
	end
end
)

