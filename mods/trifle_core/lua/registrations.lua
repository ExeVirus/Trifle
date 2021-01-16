----- Registrations

--Tile
minetest.register_node("trifle_core:tile", {
    description = "Tile",
    drawtype = "node",
    paramtype = "light",
    light_source = 11,
    tiles = {"space.png"},
})

--Life
minetest.register_node("trifle_core:life", {
    description = "Life",
    drawtype = "node",
    paramtype = "light",
    light_source = 11,
    tiles = {"life.png"},
})

--Enemy
minetest.register_node("trifle_core:enemy", {
    description = "Enemy",
    drawtype = "node",
    paramtype = "light",
    light_source = 11,
    tiles = {"enemy.png"},
})

--Structure
minetest.register_node("trifle_core:structure", {
    description = "Structure",
    drawtype = "node",
    paramtype = "light",
    light_source = 11,
    tiles = {"gray.png"},
})

--Hint
minetest.register_node("trifle_core:hint", {
    description = "Hint",
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {
            {-0.49, -0.49, -0.49, 0.49, 0.5, 0.49},
        },
    },
    paramtype = "light",
    light_source = 11,
    use_texture_alpha = true,
    tiles = {"hint.png"},
})

--Edit tool
minetest.register_item("trifle_core:editor", {
        type = "none",
        wield_image = "transparent.png",
        range = 50,
        tool_capabilities = {
            full_punch_interval=1,
            max_drop_level=1,
            groupcaps={    trifle_node={maxlevel=1, uses=0, times={[1]=2}} }
    }
})