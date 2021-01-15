-----Tutorial------



trifle.add_set("tutorial", "icon.png")

trifle.add_level("tutorial", "Intro", 1, { --level def
		size_x = 50,
		size_y = 30,
		pos    = {x=-14,y=0,z=-24},
		data   = { 	"..................................................",
					"..................................................",
					"...........................#......................",
					"..........................#.......................",
					"..........................###.....................",
					"..................................................",
					"..................................................",
					"...................**++...........................",
					"....................*++...........................",
					"..................................................",
					".......................00.........................",
					".......................00.........................",
					"..................................................",
					"..................................................",
					"..................................................",
					"..................................................",
					"..................................................",
					"...............................##.................",
					"..............................###.................",
					"...............................#..................",
					".............+++............000...0000............",
					".............+....................................",
					"..............+................+++................",
					"...............................+..+...............",
					"...............................+..................",
					"...............................+..................",
					"................................+.+...............",
					"..................................................",
					"..................................................",
					"..................................................",
				},
		round_time = 0.3,
		victory = "survive",
		final_round = 50,
})

trifle.add_level("tutorial", "Small", 2, {
	map = {
		size_x = 7,
		size_y = 7,
		pos    = {x=-4,y=0,z=-4},
		data   = { 	"..+....",
					"..+....",
					"..+....",
					".++....",
					"..+....",
					"..+....",
					"..+....",
				},		
	}
})