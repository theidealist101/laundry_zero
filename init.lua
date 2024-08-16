--Settings
local LIFETIME = minetest.settings:get("laundry_clean_lifetime") or 120
local AMBIENT_LIGHT = math.min(math.max(minetest.settings:get("hospital_ambient_light") or 5, 0), 14)
local MODPATH = minetest.get_modpath("laundry_zero")

--Particles
local function clean_particles(pos)
    return {
        amount = 100,
        time = 1,
        minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
        maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
        minvel = {x = -5, y = -5, z = -5},
        maxvel = {x = 5, y = 5, z = 5},
        minacc = {x = 0, y = 0, z = 0},
        maxacc = {x = 0, y = 0, z = 0},
        minexptime = 10,
        maxexptime = 20,
        minsize = 0.5,
        maxsize = 1.0,
        collisiondetection = false,
        vertical = false,
        texture = "tidepod.png",
        glow = 10
    }
end

local function unclean_particles(pos)
    return {
        amount = 100,
        time = 1,
        minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
        maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
        minvel = {x = -5, y = -5, z = -5},
        maxvel = {x = 5, y = 5, z = 5},
        minacc = {x = 0, y = 0, z = 0},
        maxacc = {x = 0, y = 0, z = 0},
        minexptime = 10,
        maxexptime = 20,
        minsize = 0.5,
        maxsize = 1.0,
        collisiondetection = false,
        vertical = false,
        texture = "tidepod.png^[invert:rg",
        glow = 10
    }
end

local function generate_particles(pos)
    return {
        amount = 25,
        time = 1,
        minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
        maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
        minvel = {x = 0, y = 5, z = 0},
        maxvel = {x = 0, y = 5, z = 0},
        minacc = {x = 0, y = 0, z = 0},
        maxacc = {x = 0, y = 0, z = 0},
        minexptime = 1,
        maxexptime = 3,
        minsize = 0.5,
        maxsize = 1.0,
        collisiondetection = false,
        vertical = false,
        texture = "tidepod.png",
        glow = 10
    }
end

local function portal_particles(pos)
    return {
        amount = 1,
        time = 1,
        minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
        maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
        minvel = {x = 0, y = 1, z = 0},
        maxvel = {x = 0, y = 1, z = 0},
        minacc = {x = 0, y = 0, z = 0},
        maxacc = {x = 0, y = 0, z = 0},
        minexptime = 1,
        maxexptime = 2,
        minsize = 2,
        maxsize = 4,
        collisiondetection = false,
        vertical = false,
        texture = "portal_particles.png",
        animation = {type="vertical_frames", length=-1},
        glow = 10
    }
end

local function teleport_particles(pos)
    return {
        amount = 100,
        time = 0.1,
        minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
        maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
        minvel = {x = -5, y = -5, z = -5},
        maxvel = {x = 5, y = 5, z = 5},
        minacc = {x = 0, y = 0, z = 0},
        maxacc = {x = 0, y = 0, z = 0},
        minexptime = 1,
        maxexptime = 2,
        minsize = 2,
        maxsize = 4,
        collisiondetection = false,
        vertical = false,
        texture = "portal_particles.png",
        animation = {type="vertical_frames", length=-1},
        glow = 10
    }
end

--New quests for tidepod-related stuff
table.insert_all(quests, {
    {
        type = "text",
        title = "Questline: Laundry Zero",
        text = "Some random weird mod, dunno why you downloaded this but now you've got to live with the consequences."
    },
    {
        type = "quest",
        title = "Laundry Detergent",
        requires = {"Annihilator", "Retaining Circuits", "Concrete Plan"},
        text = "Did you know you can make detergent as well for some reason? Just craft a Detergent Generator using a Conversion Chamber (that's a Matter Blob, a Matter Annihilator and a Retaining Circuit), along with 4 Core Dust, 3 Stone and a Simple Charged Field. Once you've done that, insert Charged Particles into it and it'll turn them into Detergent Pods."
    },
    {
        type = "quest",
        title = "Cleaning Things",
        requires = {"Laundry Detergent"},
        text = "So once you have Detergent Pods, what can you do with them? They're meant for cleaning clothes, but apparently you're some kind of disembodied particle trail, you don't have clothes. Wait, that means you're naked. That's weird.\n\nBut what you CAN do with them is clean things. If you use a Detergent Pod on a machine it'll make it cleaner and more efficient for a little while - and the effect does stack! Try using it on stuff and see what happens.\n\nBut DON'T EAT THEM. They're not good for you."
    },
    {
        type = "secret",
        title = "Tide Pod Challenge",
        text = "You really did it, didn't you. You ate a Detergent Pod. You awful person. See what it did to you.\n\n...I wonder what would happen if you did it again."
    },
    {
        type = "secret",
        title = "Backrooms...?",
        text = "Looks like you've eaten too many Detergent Pods and been taken to hospital. We've lost all trace of the Core and can't beam you back - but there might be some other way of getting back from here."
    },
    {
        type = "secret",
        title = "Back to Normal",
        text = "Thankfully you've escaped the hospital; now you can get back to your generating and extracting.\n\nI hope it wasn't too quick though, I did put some work into that! If I find out you spawned right next to the portal I'll be rather pissed."
    }
})

--Unbelievably hacky but it works
local old_unlock = unlock_achievement

function unlock_achievement(playername, achievement)
    if achievement ~= "Emptiness" or minetest.get_player_by_name(playername):get_pos().y > -30000 then
        old_unlock(playername, achievement)
    end
end

--Tidepod generator node, place a charged particle on it to turn it into a tidepod, uses no power
minetest.register_node("laundry_zero:detergent_generator", {
    description = "Detergent Generator",
    tiles = {"organic_converter.png^tidepod.png"},
    groups = {matter=1},
    on_rightclick = function (pos, node, user, itemstack)
        local inv = user:get_inventory()
        local tidepod = ItemStack("laundry_zero:detergent_pod")
        if itemstack:get_name() == "sbz_resources:charged_particle" and inv:room_for_item("main", tidepod) then
            itemstack:take_item()
            inv:add_item("main", tidepod)
            minetest.add_particlespawner(generate_particles(pos))
            unlock_achievement(user:get_player_name(), "Laundry Detergent")
        end
        return itemstack
    end
})

minetest.register_craft({
    output = "laundry_zero:detergent_generator",
    recipe = {
        {"sbz_resources:core_dust", "sbz_resources:stone", "sbz_resources:core_dust"},
        {"sbz_resources:stone", "sbz_resources:conversion_chamber", "sbz_resources:stone"},
        {"sbz_resources:core_dust", "sbz_resources:simple_charged_field", "sbz_resources:core_dust"},
    }
})

--Player sickness effects
local tidepod_huds = {}

local tidepod_hud_defs = {
    hud_elem_type = "image",
    position = {x=0.5, y=0.5},
    alignment = {x=0, y=0},
    offset = {x=0, y=0},
    z_index = 200,
    scale = {x=-100, y=-100},
    text = "tidepod_hud.png^[opacity:128"
}

local tidepod_fog = {
    fog_start = 0.1,
    fog_distance = 4
}
local default_fog = {
    fog_start = -1,
    fog_distance = -1
}

local tidepod_physics = {
    speed = 0.5,
    jump = 0.5
}
local default_physics = {
    speed = 1,
    jump = 1
}

local tidepod_fov = (minetest.settings:get("fov") or 72)-5

--Give player various effects to create the impression of being sick
local function add_sickness_effects(player, join)
    tidepod_huds[player] = player:hud_add(tidepod_hud_defs)
    player:set_sky({fog=tidepod_fog})
    player:set_physics_override(tidepod_physics)
    player:set_fov(tidepod_fov, false, join and 0 or 1) --fov gets broken on joining if there's a delay
end

--Remove the effects given by sickness
local function remove_sickness_effects(player)
    player:hud_remove(tidepod_huds[player])
    player:set_sky({fog=default_fog})
    player:set_physics_override(default_physics)
    player:set_fov(0, false, 1)
end

--Check sickness each step
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local meta = player:get_meta()
        local tidepod_timeout = meta:get_float("tidepod_timeout")
        local tidepod_elapsed = meta:get_float("tidepod_elapsed")
        if tidepod_elapsed < tidepod_timeout then
            meta:set_float("tidepod_elapsed", tidepod_elapsed+dtime)
            if tidepod_elapsed >= 10 and player:get_pos().y > -30000 then --small chance of going to hospital with one, but with two it's certain
                player:set_pos(vector.new(0, -30500, 0))
                unlock_achievement(player:get_player_name(), "Backrooms...?")
            end
        elseif tidepod_elapsed > 0 then
            meta:set_float("tidepod_elapsed", 0)
            meta:set_float("tidepod_timeout", 0)
            remove_sickness_effects(player)
        end
    end
end)

--Cleanable nodes and their cleaned equivalents
local cleaned = {
    ["sbz_resources:charged_field_residue"] = "sbz_resources:simple_charged_field",
    ["laundry_zero:cleaned_matter_blob"] = "laundry_zero:cleaned_cleaned_matter_blob"
}

local intervals = {}
local delays = {}

--Get timer interval for cleaned node
local function get_interval(name, level)
    if delays[name] then
        return (intervals[name] or 1)*(level*0.5+1)
    else
        return (intervals[name] or 1)/(level*0.5+1)
    end
end

--Clean node at position, making it more efficient (consume stuff slower, make stuff faster)
local function clean_node(pos)
    local node = minetest.get_node(pos)
    if cleaned[node.name] then
        node.name = cleaned[node.name]
        minetest.swap_node(pos, node)
        minetest.get_node_timer(pos):start(get_interval(node.name, 0))
        minetest.add_particlespawner(clean_particles(pos))
        return true
    elseif intervals[node.name] then
        local meta = minetest.get_meta(pos)
        local level = meta:get_int("clean_level")+1
        meta:set_int("clean_level", level)
        minetest.get_node_timer(pos):start(get_interval(node.name, level))
        minetest.add_particlespawner(clean_particles(pos))
        return true
    end
    return false
end

--Tidepod, may be placed on machines to make them more efficient, or eaten to make you sick
minetest.register_craftitem("laundry_zero:detergent_pod", {
    description = "Detergent Pod",
    inventory_image = "tidepod.png",
    on_use = function (itemstack, user)
        local meta = user:get_meta()
        meta:set_float("tidepod_timeout", meta:get_float("tidepod_timeout")+math.random(5, 10))
        if meta:get_float("tidepod_elapsed") <= 0 then add_sickness_effects(user) end
        unlock_achievement(user:get_player_name(), "Tide Pod Challenge")
        minetest.add_particlespawner(clean_particles(user:get_pos()))
        itemstack:take_item()
        return itemstack
    end,
    on_place = function (itemstack, user, pointed)
        if pointed.type == "node" and clean_node(pointed.under) then
            unlock_achievement(user:get_player_name(), "Cleaning Things")
            itemstack:take_item()
            return itemstack
        end
        minetest.item_place(itemstack, user, pointed)
    end
})

--Make sure stuff is retained after leaving and rejoining
minetest.register_on_joinplayer(function(player)
    local meta = player:get_meta()
    if meta:get_float("tidepod_elapsed") > 0 then
        add_sickness_effects(player, true)
    end
end)

--Check lifetime of cleaned node and unclean when done
local function check_lifetime(pos, node)
    local meta = minetest.get_meta(pos)
    local level = meta:get_int("clean_level")
    local lifetime = meta:get_float("lifetime")+get_interval(node.name, level)
    if lifetime >= LIFETIME then
        meta:set_float("lifetime", 0)
        minetest.add_particlespawner(unclean_particles(pos))
        if level > 0 then
            meta:set_int("clean_level", level-1)
            minetest.get_node_timer(pos):start(get_interval(node.name, level-1))
        else
            node.name = table.key_value_swap(cleaned)[node.name]
            minetest.swap_node(pos, node)
        end
        return true
    else
        meta:set_float("lifetime", lifetime)
    end
end

--Automatically make cleaned node from normal node
local function register_cleaned_node(nodename, cleaner, delayed)
    local defs = table.copy(minetest.registered_nodes[nodename])
    local newname = "laundry_zero:cleaned_"..string.sub(nodename, 15)
    defs.description = "Cleaned "..defs.description
    defs.on_timer = function (pos)
        local node = minetest.get_node(pos)
        if check_lifetime(pos, node) then return end
        return true
    end
    for _, abm_defs in ipairs(minetest.registered_abms) do
        if abm_defs.nodenames[1] == nodename then
            defs.on_timer = function (pos) --honestly, why does the game use ABMs instead of timers
                local node = minetest.get_node(pos)
                abm_defs.action(pos, node)
                if check_lifetime(pos, node) then return end
                return true
            end
            intervals[newname] = abm_defs.interval*(delayed and 1.25 or 0.8)
            delays[newname] = delayed
            break
        end
    end
    for i, tile in ipairs(defs.tiles) do
        defs.tiles[i] = tile.."^"..(cleaner and "cleaner.png" or "clean.png")
    end
    defs.drop = defs.drop and defs.drop ~= "" and defs.drop or nodename
    minetest.register_node(newname, defs)
    cleaned[nodename] = newname
end

--Various cleaned versions of nodes
register_cleaned_node("sbz_resources:matter_blob", true)
register_cleaned_node("sbz_resources:simple_matter_extractor")
register_cleaned_node("sbz_resources:advanced_matter_extractor")
register_cleaned_node("sbz_resources:simple_charge_generator", false, true)

minetest.register_node("laundry_zero:cleaned_cleaned_matter_blob", {
    description = "Cleaned Cleaned Matter Blob",
    tiles = {"cleanest.png"},
    groups = {matter=1, cracky=3},
    sounds = {footstep={name="step", gain=1.0}},
    on_punch = function(pos)
        minetest.sound_play("step", {pos=pos, gain=1.0})
    end
})

--Various nodes found in the hospital
minetest.register_node("laundry_zero:cleaned_air", {
    description = "| || || |_",
    drawtype = "airlike",
    walkable = false,
    pointable = false,
    paramtype = "light",
    sunlight_propagates = true,
    light_source = AMBIENT_LIGHT
})

minetest.register_node("laundry_zero:super_clean", {
    description = "Super Clean",
    tiles = {"cleanest.png"},
    sounds = {footstep={name="step", gain=1.0}},
    on_punch = function(pos)
        minetest.sound_play("step", {pos=pos, gain=1.0})
    end
})

minetest.register_node("laundry_zero:cleaned_floor", {
    description = "Cleaned Floor",
    tiles = {"cleaned_floor.png"},
    sounds = {footstep={name="step", gain=1.0}},
    on_punch = function(pos)
        minetest.sound_play("step", {pos=pos, gain=1.0})
    end
})

minetest.register_node("laundry_zero:bed_head", {
    description = "Bed Head",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={
        {-0.5, -0.25, -0.5, 0.5, 0, 0.5},
        {-0.5, -0.5, 0.375, -0.375, -0.25, 0.5},
        {0.375, -0.5, 0.375, 0.5, -0.25, 0.5}
    }},
    tiles = {"bed_head.png", "cleanest.png", "bed_head_side.png^[transform4", "bed_head_side.png", "bed_head_end.png", "bed_foot_end.png"},
    paramtype = "light",
    paramtype2 = "4dir",
    sunlight_propagates = true
})

minetest.register_node("laundry_zero:bed_foot", {
    description = "Bed Foot",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={
        {-0.5, -0.25, -0.5, 0.5, 0, 0.5},
        {-0.5, -0.5, -0.5, -0.375, -0.25, -0.375},
        {0.375, -0.5, -0.5, 0.5, -0.25, -0.375}
    }},
    tiles = {"bed_foot.png", "cleanest.png", "bed_foot_side.png^[transform4", "bed_foot_side.png", "bed_foot_end.png", "bed_foot_end.png"},
    paramtype = "light",
    paramtype2 = "4dir",
    sunlight_propagates = true
})
minetest.register_node("laundry_zero:blue_cross", {
    description = "Blue Cross",
    drawtype = "signlike",
    tiles = {"blue_cross.png"},
    inventory_image = "blue_cross.png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    pointable = false
})

minetest.register_node("laundry_zero:cleaned_slab_lower", {
    description = "Cleaned Slab",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.5, -0.5, -0.5, 0.5, 0, 0.5}},
    tiles = {"cleaned_floor.png"},
    paramtype = "light",
    sunlight_propagates = true,
    sounds = {footstep={name="step", gain=1.0}},
    on_punch = function(pos)
        minetest.sound_play("step", {pos=pos, gain=1.0})
    end
})

minetest.register_node("laundry_zero:cleaned_slab_upper", {
    description = "Cleaned Slab",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.5, 0, -0.5, 0.5, 0.5, 0.5}},
    tiles = {"cleaned_floor.png"},
    paramtype = "light",
    sunlight_propagates = true,
    sounds = {footstep={name="step", gain=1.0}},
    on_punch = function(pos)
        minetest.sound_play("step", {pos=pos, gain=1.0})
    end
})

minetest.register_node("laundry_zero:cleaned_glass", {
    description = "Cleaned Glass",
    drawtype = "glasslike",
    tiles = {"cleaned_glass.png^[opacity:224"},
    use_texture_alpha = "blend",
    paramtype = "light"
})

minetest.register_craftitem("laundry_zero:remover", {
    description = "Remover",
    inventory_image = "matter_annihilator.png",
    stack_max = 1,
    groups = {not_in_creative_inventory=1},
    on_use = function (_, _, pointed)
        if pointed.type ~= "node" then return end
        minetest.remove_node(pointed.under)
    end
})

do
    local defs = table.copy(minetest.registered_nodes["laundry_zero:detergent_generator"])
    defs.groups = {}
    defs.description = "Unbreakable "..defs.description
    minetest.register_node("laundry_zero:unbreakable_detergent_generator", defs)
end

--Portal, special hospital node which teleports you to the core on entering
minetest.register_node("laundry_zero:portal", {
    description = "Portal",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.5, -0.5, -0.5, 0.5, 0, 0.5}},
    tiles = {{name="portal.png^[opacity:224", animation={type="vertical_frames", length=0.3}}, "blank.png"},
    inventory_image = "portal.png^[verticalframe:2:1",
    wield_image = "portal.png^[verticalframe:2:1",
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    light_source = 14
})

minetest.register_abm({
    nodenames = {"laundry_zero:portal"},
    interval = 1,
    chance = 2,
    action = function (pos)
        if #minetest.get_objects_inside_radius(pos, 16) > 0 then --otherwise there would be literal thousands of particle spawners at once, breaking the client
            minetest.add_particlespawner(portal_particles(pos))
        end
    end
})

local core_pos = vector.new(0, 1, 0)

minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        if minetest.get_node(vector.apply(player:get_pos()+vector.new(0, 0.01, 0), math.round)).name == "laundry_zero:portal" then
            player:set_pos(core_pos)
            minetest.add_particlespawner(teleport_particles(core_pos))
            unlock_achievement(player:get_player_name(), "Back to Normal")
            displayDialougeLine(player:get_player_name(), "Beamed you back to the Core.")
        end
    end
end)

--Disable /core when in hospital - that would be cheating
minetest.override_chatcommand("core", {
    func = function (name)
        local player = minetest.get_player_by_name(name)
        if player:get_pos().y > -30000 or minetest.check_player_privs(name, "teleport") then
            player:set_pos(core_pos)
            displayDialougeLine(name, "Beamed you back to the Core.")
        else
            displayDialougeLine(name, "Out of range, unable to beam back to the Core.")
        end
    end
})

--Terrain generation data
local vm_data = {}

local layers = {
    [-30912] = minetest.get_content_id("laundry_zero:super_clean"),
    [-30001] = minetest.get_content_id("laundry_zero:super_clean"),
    [-30000] = minetest.get_content_id("laundry_zero:portal")
}

local room_types = {
    {"hospital_room", 3, {true, false, false, false}},
    {"hospital_cross", 2, {true, true, true, true}},
    {"hospital_junct", 2, {true, true, false, true}},
    {"hospital_corner", 3, {true, false, false, true}},
    {"hospital_corridor", 3, {false, true, false, true}},
    {"hospital_staircase_bottom", 2, {true, false, false, false}},
    {"hospital_staircase_top", 2, {true, false, false, false}},
    {"hospital_portal", 1, {true, false, false, false}},
    {"hospital_storage", 2, {true, false, false, false}}
}

local up = vector.new(0, 5, 0)

local undecided = {"air", "ignore", "laundry_zero:cleaned_glass"}

local c_glass = minetest.get_content_id("laundry_zero:cleaned_glass")

local glass_cache = {[0]={[0]=false}}

minetest.set_mapgen_setting("mg_flags", "nocaves", true)

--Some basic room functions
local function rotate_connects(connects, rot)
    if rot == 0 then return connects end
    for _ = 1, rot do
        connects = {connects[4], connects[1], connects[2], connects[3]}
    end
    return connects
end

local function place_room(vm, pos, room)
    minetest.place_schematic_on_vmanip(vm, pos, MODPATH.."/schems/"..room_types[room[1]][1]..".mts", tostring(room[2]*90), {}, true, "place_center_x, place_center_z")
end

local function room_fits(vm, pos, room_type, rot, ignore_other)
    local current_node = vm:get_node_at(pos).name
    if current_node ~= "air" and current_node ~= "ignore" then return false end
    local tuple = room_types[room_type]
    tuple = {tuple[1], rotate_connects(tuple[3], rot)}
    for i = 0, 3 do
        local testpos = pos+minetest.fourdir_to_dir((i+3)%4)*4 --I spent SO FUCKING LONG trying to find the bug and all I had to do was rotate this? I'm gonna kill somebody
        local testnode = vm:get_node_at(testpos).name
        if table.indexof(undecided, testnode) < 0 and tuple[2][i+1] ~= (testnode == "laundry_zero:cleaned_air") then return false end
    end
    if ignore_other then return true end
    return (room_type ~= 6 or room_fits(vm, pos+up, 7, rot, true))
    and (room_type ~= 7 or room_fits(vm, pos-up, 6, rot, true))
end

local function weighted_choice(options)
    if #options == 0 then return {nil, nil} end
    local total = 0
    for _, tuple in ipairs(options) do
        total = total+tuple[3]
    end
    local pointer = math.random()*total
    for _, tuple in ipairs(options) do
        pointer = pointer-tuple[3]
        if pointer < 0 then return {tuple[1], tuple[2]} end
    end
    return {nil, nil} --shouldn't ever happen
end

local function is_glass(x, z)
    x = math.round(x/21)
    z = math.round(z/21)
    glass_cache[x] = glass_cache[x] or {}
    if glass_cache[x][z] == nil then
        glass_cache[x][z] = (PcgRandom(x+PcgRandom(z):next()):next(0, 9) == 0)
    end
    return glass_cache[x][z]
end

--Choose room randomly to fit surrounding rooms
local function choose_room(vm, pos)
    local options = {}
    for room_type, room in ipairs(room_types) do
        for rot = 1, 4 do
            if room_fits(vm, pos+vector.new(0, 1, 0), room_type, rot) then
                table.insert(options, {room_type, rot, room[2]})
            end
        end
    end
    local out = weighted_choice(options)
    if not out[1] then return end
    if out[1] == 6 then place_room(vm, pos+up, {7, out[2]})
    elseif out[1] == 7 then place_room(vm, pos-up, {6, out[2]}) end
    return out
end

--Hospital terrain generation lol
minetest.register_on_generated(function (minp, maxp)
    local size = maxp.x-minp.x+1

    --only bother to do stuff if we're under -30000
    if minp.y > -30000 then return end

    --set up VM data
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
    vm:get_data(vm_data)

    --place layers on top and bottom
    for y, id in pairs(layers) do
        if minp.y <= y and maxp.y >= y then
            for z = minp.z, maxp.z do
                local vi = area:index(minp.x, y, z)-1
                for i = 1, size do
                    vm_data[vi+i] = id
                end
            end
        end
    end

    --add occasional shafts of glass
    for y = minp.y, maxp.y do
        if y > -30912 and y < -30001 then
            for z = minp.z, maxp.z do
                local vi = area:index(minp.x, y, z)
                for x = minp.x, maxp.x do
                    if is_glass(x, z) then
                        vm_data[vi] = c_glass
                    end
                    vi = vi+1
                end
            end
        end
    end
    vm:set_data(vm_data)

    --place cross room at spawn point
    place_room(vm, vector.new(0, -30501, 0), {2, 0})

    --generate all rooms with their centers in the chunk
    for x = math.ceil(minp.x/7), math.floor(maxp.x/7) do
        for y = math.ceil(math.max(minp.y+30911, 0)*0.2), math.floor(math.min(maxp.y+30911, 905)*0.2) do
            for z = math.ceil(minp.z/7), math.floor(maxp.z/7) do
                local pos = vector.new(x*7, y*5-30911, z*7)
                local room = choose_room(vm, pos)
                if room then place_room(vm, pos, room) end
            end
        end
    end

    --finish up and save data
    vm:calc_lighting()
    vm:write_to_map()
    vm:update_liquids()
end)

--Aliases for schematics
minetest.register_alias("tidepod_zero:super_clean", "laundry_zero:super_clean")
minetest.register_alias("tidepod_zero:cleaned_air", "laundry_zero:cleaned_air")
minetest.register_alias("tidepod_zero:cleaned_floor", "laundry_zero:cleaned_floor")
minetest.register_alias("tidepod_zero:blue_cross", "laundry_zero:blue_cross")
minetest.register_alias("tidepod_zero:unbreakable_tidepod_generator", "laundry_zero:unbreakable_detergent_generator")
minetest.register_alias("tidepod_zero:cleaned_glass", "laundry_zero:cleaned_glass")
minetest.register_alias("tidepod_zero:portal", "laundry_zero:portal")
minetest.register_alias("tidepod_zero:cleaned_slab_lower", "laundry_zero:cleaned_slab_lower")
minetest.register_alias("tidepod_zero:cleaned_slab_upper", "laundry_zero:cleaned_slab_upper")
minetest.register_alias("tidepod_zero:bed_head", "laundry_zero:bed_head")
minetest.register_alias("tidepod_zero:bed_foot", "laundry_zero:bed_foot")