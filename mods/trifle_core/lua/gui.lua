--------- GUI ------------

--Main formspec for game
function trifle.main_formspec()
	local r = {
        "formspec_version[3]",
        "size[9,11.5]",
		"position[0.5,0.5]",
		"anchor[0.5,0.5]",
		"no_prepend[]",
		"bgcolor[#EAD994FF;both;#00000080]",
		--"box[1.12,0.2;6.8,1.2;#00000030]",
		--"image[1.2,0.3;6.6,1;title.png]",
		"hypertext[0.3,1.5;8.4,9.5;play;",
        "<global halign=center color=#000 size=24 font=Regular>",
        "  -----------   Trifle   ----------- \n",
        "<global halign=center>",
        "You are encourged to <action name=play><style color=#000 size=18>(Click me)</style></action>\n", 
		"]",
    }
	return table.concat(r);
end