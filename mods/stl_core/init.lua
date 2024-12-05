stellua = {}

--Shut up VS code
table.insert_all = table.insert_all
table.indexof = table.indexof
math.round = math.round
table.copy = table.copy
math.hypot = math.hypot

--Got this from the old Luamap, it's very useful
function stellua.remap(val, min_val, max_val, min_map, max_map)
	return (val-min_val)/(max_val-min_val) * (max_map-min_map) + min_map
end

local modpath = minetest.get_modpath("stl_core").."/"
dofile(modpath.."sounds.lua")
dofile(modpath.."slots.lua")
dofile(modpath.."names.lua")
dofile(modpath.."trees.lua")
dofile(modpath.."nodes.lua")
dofile(modpath.."mapgen.lua")
dofile(modpath.."sky.lua")
dofile(modpath.."crafts.lua")
dofile(modpath.."inventory.lua")

--Spawn player in a good place
local start_planet

minetest.register_on_mods_loaded(function()
    for i, planet in ipairs(stellua.planets) do
        if 200 < planet.heat_stat and planet.heat_stat < 350 and planet.scale < 1.1
        and 0.5 <= planet.atmo_stat and planet.atmo_stat <= 2 and planet.life_stat > 1 then --more to be added later
            start_planet = i
        end
    end
    if not start_planet then --try again with less strict requirements
        for i, planet in ipairs(stellua.planets) do
            if 150 <= planet.heat_stat and planet.heat_stat <= 400
            and planet.scale < 1.1 and 0.5 <= planet.atmo_stat and planet.life_stat > 0.5 then
                start_planet = i
            end
        end
    end
    if not start_planet then --give up
        start_planet = 1
    end
end)

minetest.register_on_newplayer(function(player)
    local pos = vector.round(vector.new(0, stellua.get_planet_level(start_planet)+10^stellua.planets[start_planet].scale+60, 0))
    player:set_pos(pos+vector.new(0, 1.5, 0))
    stellua.set_respawn(player, pos+vector.new(0, 1, 0))
    if stellua.detach_vehicle then
        minetest.place_schematic(pos, modpath.."schems/starter_rocket.mts", "0", {}, true, "place_center_x, place_center_z")
        minetest.registered_nodes["stl_vehicles:tank"].on_construct(pos+vector.new(0, 4, 0))
    end
end)

--Make player respawn in their spaceship on death
function stellua.set_respawn(player, pos)
    player:get_meta():set_string("respawn", minetest.serialize(pos))
    minetest.chat_send_player(player:get_player_name(), "Respawn point set!")
end

minetest.register_on_respawnplayer(function(player)
    local respawn = player:get_meta():get_string("respawn")
    player:set_pos(minetest.deserialize(respawn))
    return true
end)

--A few useful commands
minetest.register_chatcommand("planet", {
    params = "",
    description = "Get info about the current planet",
    privs = {debug=true},
    func = function (playername)
        local index = stellua.get_planet_index(minetest.get_player_by_name(playername):get_pos().y)
        if not index then return false, "Not currently in a planet" end
        local planet = stellua.planets[index]
        return true, "Name: "..planet.name.."\nSeed: "..planet.seed.."   Scale: "..planet.scale.."\nHeat: "..planet.heat_stat.."K\nAtmosphere: "..planet.atmo_stat.."atm\n"..(planet.water_level and planet.water_name.." Level: "..(planet.water_level-planet.level) or "No surface liquid").."\nLife: "..planet.life_stat.."   Dist: "..(math.round(planet.dist*1000)*0.001).."AU"
    end
})

minetest.register_chatcommand("star", {
    params = "",
    description = "Get info about the current star system",
    privs = {debug=true},
    func = function (playername)
        local index = stellua.get_planet_index(minetest.get_player_by_name(playername):get_pos().y)
        if not index then return false, "Not currently in a planet" end
        local star = stellua.stars[stellua.planets[index].star]
        return true, "Name: "..star.name.."\nSeed: "..star.seed.."\nScale: "..star.scale.."\nPlanets: "..#star.planets.."\nPosition: ("..star.pos.x..", "..star.pos.y..", "..star.pos.z..")"
    end
})