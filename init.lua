--Settings
local LIFETIME = minetest.settings:get("tidepod_clean_lifetime") or 120
local AMBIENT_LIGHT = math.min(math.max(minetest.settings:get("hospital_ambient_light") or 5, 0), 14)

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

--Tidepod generator node, place a charged particle on it to turn it into a tidepod, uses no power
minetest.register_node("tidepod_zero:tidepod_generator", {
    description = "Tide Pod Generator",
    tiles = {"organic_converter.png^tidepod.png"},
    groups = {matter=1},
    on_rightclick = function (pos, node, user, itemstack)
        local inv = user:get_inventory()
        local tidepod = ItemStack("tidepod_zero:tidepod")
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
    output = "tidepod_zero:tidepod_generator",
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
    ["tidepod_zero:cleaned_matter_blob"] = "tidepod_zero:cleaned_cleaned_matter_blob"
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

--New quests for tidepod-related stuff
table.insert_all(quests, {
    {title="Laundry Detergent", text="Did you know you can make detergent as well for some reason? Just craft a Tide Pod Generator using a Conversion Chamber (that's a Matter Blob, a Matter Annihilator and a Retaining Circuit), along with 4 Core Dust, 3 Stone and a Simple Charged Field. Once you've done that, insert Charged Particles into it and it'll turn them into Tide Pods."},
    {title="Cleaning Things", text="So once you have Tide Pods, what can you do with them? They're meant for cleaning clothes, but apparently you're some kind of disembodied particle trail, you don't have clothes. Wait, that means you're naked. That's weird.\n\nBut what you CAN do with them is clean things. If you use a Tide Pod on a machine it'll make it cleaner and more efficient for a little while - and the effect does stack! Try using it on stuff and see what happens.\n\nBut DON'T EAT THEM. They're not good for you."}
})

local secret_quests = {
    ["Tide Pod Challenge"] = "You really did it, didn't you. You ate a Tide Pod. You awful person. See what it did to you.\n\n...I wonder what would happen if you did it again."
}

--Secret quests for tidepod eating
local function grant_secret_achievement(player, name)
    local playername = player:get_player_name()
    local text = secret_quests[name]
    if text and not is_achievement_unlocked(playername, name) then
        table.insert(quests, {title=name, text=secret_quests[name]})
        unlock_achievement(playername, name)
    end
end

--Tidepod, may be placed on machines to make them more efficient, or eaten to make you sick
minetest.register_craftitem("tidepod_zero:tidepod", {
    description = "Tide Pod",
    inventory_image = "tidepod.png",
    on_use = function (itemstack, user)
        local meta = user:get_meta()
        meta:set_float("tidepod_timeout", meta:get_float("tidepod_timeout")+math.random(5, 10))
        if meta:get_float("tidepod_elapsed") <= 0 then add_sickness_effects(user) end
        grant_secret_achievement(user, "Tide Pod Challenge")
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
    for title, text in pairs(secret_quests) do
        if meta:get_string(title) == "true" then
            table.insert(quests, {title=title, text=text})
        end
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
    local newname = "tidepod_zero:cleaned_"..string.sub(nodename, 15)
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
            delays[newname] = true
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

minetest.register_node("tidepod_zero:cleaned_cleaned_matter_blob", {
    description = "Cleaned Cleaned Matter Blob",
    tiles = {"cleanest.png"},
    groups = {matter=1, cracky=3},
    sounds = {footstep={name="step", gain=1.0}},
    on_punch = function(pos)
        minetest.sound_play("step", {pos=pos, gain=1.0})
    end
})

--Various nodes found in the hospital
minetest.register_node("tidepod_zero:cleaned_air", {
    description = "| || || |_",
    drawtype = "airlike",
    walkable = false,
    paramtype = "light",
    sunlight_propagates = true,
    light_source = AMBIENT_LIGHT
})

minetest.register_node("tidepod_zero:super_clean", {
    description = "Super Clean",
    tiles = {"cleanest.png"},
    sounds = {footstep={name="step", gain=1.0}},
    on_punch = function(pos)
        minetest.sound_play("step", {pos=pos, gain=1.0})
    end
})

minetest.register_node("tidepod_zero:cleaned_floor", {
    description = "Cleaned Floor",
    tiles = {"cleaned_floor.png"},
    sounds = {footstep={name="step", gain=1.0}},
    on_punch = function(pos)
        minetest.sound_play("step", {pos=pos, gain=1.0})
    end
})

minetest.register_node("tidepod_zero:bed_head", {
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

minetest.register_node("tidepod_zero:bed_foot", {
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
minetest.register_node("tidepod_zero:blue_cross", {
    description = "Blue Cross",
    drawtype = "signlike",
    tiles = {"blue_cross.png"},
    inventory_image = "blue_cross.png",
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false
})

minetest.register_node("tidepod_zero:cleaned_slab_lower", {
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

minetest.register_node("tidepod_zero:cleaned_slab_upper", {
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

minetest.register_craftitem("tidepod_zero:remover", {
    description = "Remover",
    inventory_image = "matter_annihilator.png",
    stack_max = 1,
    groups = {not_in_creative_inventory=1},
    on_use = function (_, _, pointed)
        if pointed.type ~= "node" then return end
        minetest.remove_node(pointed.under)
    end
})

minetest.register_node("tidepod_zero:portal", {
    description = "Portal",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.5, -0.5, -0.5, 0.5, 0, 0.5}},
    tiles = {"portal.png"},
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 14
})

do
    local defs = table.copy(minetest.registered_nodes["tidepod_zero:tidepod_generator"])
    defs.groups = {}
    defs.description = "Unbreakable "..defs.description
    minetest.register_node("tidepod_zero:unbreakable_tidepod_generator", defs)
end