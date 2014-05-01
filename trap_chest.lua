minetest.register_node("lockpicks:trap_chest", {
	description = "Locked Chest",
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_lock.png"},
	paramtype2 = "facedir",
	groups = {choppy=2,oddly_breakable_by_hand=2,locked=3},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
		meta:set_string("infotext", "Locked Chest (owned by "..
				meta:get_string("owner")..")")
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Locked Chest")
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		if player:get_wielded_item():get_tool_capabilities().groupcaps.locked then
			if player:get_wielded_item():get_tool_capabilities().groupcaps.locked.maxlevel >= 1 then
				return true
			end
		end
		return inv:is_empty("main") and has_locked_chest_privilege(meta, player)
	end,
	on_punch = function(pos, node, puncher, pointed_thing)
		local meta = minetest.get_meta(pos)
		if puncher:get_wielded_item():get_tool_capabilities().groupcaps.locked then
			if puncher:get_wielded_item():get_tool_capabilities().groupcaps.locked.maxlevel >= 1 then
				minetest.chat_send_player(meta:get_string("owner"),"Someone is picking your lock at "..minetest.pos_to_string(pos), true)
			end
		end
	end,
	on_dig = function(pos, node, digger)
		
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		local inv_list = inv:get_list("main")
		--if player dug chest with a lockpick
		if digger:get_wielded_item():get_tool_capabilities().groupcaps.locked then
			if digger:get_wielded_item():get_tool_capabilities().groupcaps.locked.maxlevel >= 1 then
				minetest.set_node(pos, {name="lockpicks:mesecons_chest_on",paramtype2=node.param2})
				local n_meta = minetest.get_meta(pos)
				local n_inv = n_meta:get_inventory()
				n_inv:set_list("main", inv_list)
				mesecon:receptor_on(pos)
			end
		end
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_chest_privilege(meta, player) then
			minetest.log("action", player:get_player_name()..
					" tried to access a locked chest belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return count
	end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_chest_privilege(meta, player) then
			minetest.log("action", player:get_player_name()..
					" tried to access a locked chest belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return stack:get_count()
	end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if not has_locked_chest_privilege(meta, player) then
			minetest.log("action", player:get_player_name()..
					" tried to access a locked chest belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return stack:get_count()
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff in locked chest at "..minetest.pos_to_string(pos))
	end,
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff to locked chest at "..minetest.pos_to_string(pos))
	end,
    on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" takes stuff from locked chest at "..minetest.pos_to_string(pos))
	end,
	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		if has_locked_chest_privilege(meta, clicker) then
			minetest.show_formspec(
				clicker:get_player_name(),
				"default:chest_locked",
				default.get_locked_chest_formspec(pos)
			)
		end
	end,
	mesecons = {receptor = {
   	state = mesecon.state.off
 	}}
})



--create a formspec for the mesecons chest
chest_formspec = 
	"size[8,9]"..
	"list[current_name;main;0,0;8,4;]"..
	"list[current_player;main;0,5;8,4;]"
	
--mesecons chest receptor
--chest off-state
minetest.register_node("lockpicks:mesecons_chest_off", {
description = "Mesecons Chest",
tiles = {"mesecons_chest_top.png", "mesecons_chest_top.png", "mesecons_chest_side.png",
	"mesecons_chest_side.png", "mesecons_chest_side.png", "mesecons_chest_front.png"},
paramtype2 = "facedir",
groups = {choppy=2,oddly_breakable_by_hand=2},
legacy_facedir_simple = true,
is_ground_content = false,
sounds = default.node_sound_wood_defaults(),
on_construct = function(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec",chest_formspec)
	meta:set_string("infotext", "Chest")
	local inv = meta:get_inventory()
	inv:set_size("main", 8*4)
end,
can_dig = function(pos,player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("main")
end,
on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
	minetest.log("action", player:get_player_name()..
			" moves stuff in chest at "..minetest.pos_to_string(pos))
end,
   on_metadata_inventory_put = function(pos, listname, index, stack, player)
	minetest.log("action", player:get_player_name()..
			" moves stuff to chest at "..minetest.pos_to_string(pos))
end,
   on_metadata_inventory_take = function(pos, listname, index, stack, player)
	minetest.log("action", player:get_player_name()..
			" takes stuff from chest at "..minetest.pos_to_string(pos))
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	--if nothing is in the chest, activate it.
	if inv:is_empty("main") then
		minetest.swap_node(pos, {name="lockpicks:mesecons_chest_on", param2=node.param2})
		mesecon:receptor_on(pos)
	end
end,
mesecons = {receptor = {
   	state = mesecon.state.off
 	}}
})

--Chest on-state
minetest.register_node("lockpicks:mesecons_chest_on", {
description = "Mesecons Chest",
tiles = {"mesecons_chest_top_on.png", "mesecons_chest_top_on.png", "mesecons_chest_side_on.png",
	"mesecons_chest_side_on.png", "mesecons_chest_side_on.png", "mesecons_chest_front_on.png"},
paramtype2 = "facedir",
groups = {choppy=2,oddly_breakable_by_hand=2},
legacy_facedir_simple = true,
is_ground_content = false,
sounds = default.node_sound_wood_defaults(),
on_construct = function(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec",chest_formspec)
	meta:set_string("infotext", "Chest")
	local inv = meta:get_inventory()
	inv:set_size("main", 8*4)
end,
can_dig = function(pos,player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("main")
end,
on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
	minetest.log("action", player:get_player_name()..
			" moves stuff in chest at "..minetest.pos_to_string(pos))
end,
   on_metadata_inventory_put = function(pos, listname, index, stack, player)
	minetest.log("action", player:get_player_name()..
			" moves stuff to chest at "..minetest.pos_to_string(pos))
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	--if something is in the chest, turn it off.
	if not inv:is_empty("main") then
		minetest.swap_node(pos, {name="lockpicks:mesecons_chest_off", param2=node.param2})
		mesecon:receptor_off(pos)
	end
end,
   on_metadata_inventory_take = function(pos, listname, index, stack, player)
	minetest.log("action", player:get_player_name()..
			" takes stuff from chest at "..minetest.pos_to_string(pos))
end,
mesecons = {receptor = {
   	state = mesecon.state.on
 	}}
})
--register easier-to-use aliases
minetest.register_alias("mesecons:mesecons_chest", "lockpicks:mesecons_chest_off")
minetest.register_alias("lockpicks:mesecons_chest", "lockpicks:mesecons_chest_off")
--register craft recipe
minetest.register_craft({
	output = "lockpicks:mesecons_chest_off",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "mesecons:mesecon", "group:wood"},
		{"group:wood", "group:wood", "groups:wood"}
	}
})
minetest.register_craft({
	output = "lockpicks:trap_chest",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "mesecons:object_detector", "group:wood"},
		{"group:wood", "group:wood", "groups:wood"}
	}
})