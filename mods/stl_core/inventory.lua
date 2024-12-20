sfinv.register_page("stl_core:planets", {
    title = "Planets",
    get = function (self, player, context)
        local out = {}
        local index = stellua.get_planet_index(player:get_pos().y)
        local slot = stellua.get_slot_index(player:get_pos())
        if not context.planet then context.planet = index or 0 end
        if context.planet == 0 then
            local x, y = 0, 0.5
            for i, star in ipairs(stellua.stars) do
                table.insert(out, "image_button["..(x*2)..","..(y*2)..";2,2;sun.png;star"..i..";"..star.name.."]")
                x = x+1
                if x > 3 then x, y = 0, y+1 end
            end
        elseif context.planet < 0 then
            local x, y = 0, 0.5
            for _, i in ipairs(stellua.stars[-context.planet].planets) do
                local planet = stellua.planets[i]
                table.insert(out, "image_button["..(x*2)..","..(y*2)..";2,2;"..planet.icon..";planet"..i..";"..planet.name.."]")
                x = x+1
                if x > 3 then x, y = 0, y+1 end
            end
            table.insert(out, "button[0,-0.15;1,1;back;<]")
        else
            local planet = stellua.planets[context.planet]
            local info = {
                "Average Temperature: "..planet.heat_stat.."K",
                "Atmospheric Pressure: "..planet.atmo_stat.."atm",
                planet.water_level and string.sub(planet.water_name, 1, 1)..string.lower(string.sub(planet.water_name, 2)).." oceans" or "No surface liquid",
                planet.life_stat > 1 and "High biodiversity" or planet.life_stat > 0.5 and "Low biodiversity" or planet.life_stat > 0 and "Only low-lying grasses" or "No plant life",
                (planet.depth_filler == 0 and "Surface" or planet.water_level and planet.depth_seabed == 0 and "Seabed" or "Underground").." "..planet.ore_common.." deposits"
            }
            if planet.caves then table.insert(info, "Narrow cave systems") end
            for _, resource in ipairs({planet.snow_type1 or "", planet.snow_type2 ~= planet.snow_type1 and planet.snow_type2 or "", planet.life_stat > 1.5 and "stl_core:moss1" or "", planet.quartz or "", planet.crystal or ""}) do
                if resource ~= "" then table.insert(info, minetest.registered_nodes[resource].description) end
            end
            if planet.scale > 1.1 then table.insert(info, "WARNING: HIGH GRAVITY") end
            out = {
                "label[0,2;"..table.concat(info, "\n").."]",
                "style_type[label;font_size=*3]",
                "label[0,1;"..planet.name.."]",
                "image[5,0.5;3,3;"..planet.icon..";]",
                "button[0,-0.15;1,1;back;<]"
            }
            if slot then
                local star, pos = stellua.get_slot_info(slot)
                local cost = planet.star == star and vector.distance(planet.pos, pos) or 16*vector.distance(stellua.stars[planet.star].pos, stellua.stars[star].pos)
                table.insert(out, "button[1,-0.15;3,1;tp;Go here ("..math.round(cost+0.3).." Uranium)]")
            end
        end
        return sfinv.make_formspec(player, context, table.concat(out), false)
    end,
    on_player_receive_fields = function (self, player, context, fields)
        if fields.back then
            context.planet = context.planet and context.planet > 0 and -stellua.planets[context.planet].star or 0
            sfinv.set_page(player, "stl_core:planets")
            return
        end
        if fields.tp then
            local slot = stellua.get_slot_index(player:get_pos())
            local ent = stellua.detach_vehicle(stellua.get_slot_pos(slot))
            local planet = stellua.planets[context.planet]
            local star, spos = stellua.get_slot_info(slot)
            local cost = planet.star == star and vector.distance(planet.pos, spos) or 16*vector.distance(stellua.stars[planet.star].pos, stellua.stars[star].pos)
            local fuel, ignite = stellua.get_fuel(ent.tanks, cost, "fissile")
            if not fuel then
                stellua.land_vehicle(ent, stellua.get_slot_pos(slot))
                minetest.chat_send_player(player:get_player_name(), "Not enough impulse fuel!")
                if ignite then minetest.sound_play({name="fire_flint_and_steel", gain=0.2}, {pos=stellua.get_slot_pos(slot)}, true) end
                return
            end
            local pos = vector.new(0, stellua.get_planet_level(context.planet)+150, 0)
            ent.player = player:get_player_name()
            ent.object:set_pos(pos)
            player:set_pos(pos)
            context.planet = nil
            minetest.close_formspec(player:get_player_name(), "")
            if ignite then minetest.sound_play({name="fire_flint_and_steel", gain=0.2}, {object=ent.object}, true) end
        end
        for i = 1, 60 do
            if fields["planet"..i] then
                context.planet = i
                sfinv.set_page(player, "stl_core:planets")
                return
            end
        end
        for i = 1, 16 do
            if fields["star"..i] then
                context.planet = -i
                sfinv.set_page(player, "stl_core:planets")
                return
            end
        end
    end
})