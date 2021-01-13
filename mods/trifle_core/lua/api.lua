-----External Focused API-----

function trifle.add_set(name_of_set, icon_texture_name)
	if not trifle.levels.name_of_set then
		trifle.levels[name_of_set] = {}
		trifle.levels.num = trifle.levels.num+1
		trifle.levels[trifle.levels.num] = name_of_set
		trifle.levels[name_of_set].icon = icon_texture_name
	else
		minetest.log("Unable to register new trifle game set: "..name_of_set..". It already exists!")
	end
end

--level_file is a table containing a .map among callbacks and whatnot
function trifle.add_level(name_of_set, name_of_level, level_number, level_file)
	if not trifle.levels[name_of_set][level_number] then
		trifle.levels[name_of_set][level_number] = {}
		trifle.levels[name_of_set][level_number].name = name_of_level
		trifle.levels[name_of_set][level_number].level = level_file
	else
		minetest.log("Unable to register new "..name_of_set.." level number "..level_number..". It already exists!")
	end
end
