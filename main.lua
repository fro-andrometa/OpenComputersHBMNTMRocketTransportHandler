local term = require("term")
local function table_length(input_table)
	assert(type(input_table) == "table", "PROVIDE A TABLE!") 
	local n = 0
	for _,_ in pairs(input_table) do n = n + 1 end
	return n
end

--@param1: transposer: Component (typically a Proxy, or a getPrimary)
--@param2: block_side: int
--@param3: inventory_offset: int: (optional) | used to offset for detecting items within an hbm ntm extractor
--@param4: cancel_early: boolean: (optional) | cancels if a single item is found.
--return: {[int]: [} | key-value pair of slot number & the item contained within, along with relevant info.
local function detect_item(transposer, block_side, inventory_offset, cancel_early)
	assert(type(transposer) == "table" and transposer["getStackInSlot"] and transposer["getInventorySize"], "Transposer provided was not of a Transposer Component!")
	assert(type(block_side) == "number" and block_side >= 0 and block_side <= 5, "Block side provided was not a valid side!")
	assert(type(inventory_offset) == "number" or type(inventory_offset) == "nil", "Inventory offset was not a number or nothing!")

	if not inventory_offset then inventory_offset = 0 end
	local inventory_size = transposer.getInventorySize(block_side)
	local items = {}
	if not inventory_size then return {} end
	for i = 1 + inventory_offset, inventory_size do
		local item = transposer.getStackInSlot(block_side, i)
		if not item then goto detect_item_continue end
		items[i] = {name = item.name, stack = item.size}
		if cancel_early then return items end
		::detect_item_continue::
	end
	return items
end

local component = require("component")
local transposers = component.list("transposer")
local spatial_io_signal = component.list("redstone")
assert(table_length(transposers) == 1, "Number of transposers connected must be exactly one! Current amount: "..tostring(table_length(transposers))
assert(table_length(spatial_io_signal) == 1, "Number of redstone controllers connected must be exactly one! Current amount: "..tostring(table_length))

local transposer = next(transposers)
local spatial_io_signaller = next(spatial_io_signal)

transposer = component.proxy(transposer)
spatial_io_signaller = component.proxy(spatial_io_signaller) -- screw you lua for the select function not being an index function for varargs..)

local inventory_sides = {}
for i = 0, 5 do -- getting all inventories with tile names and stuff..
	local inventory_name = transposer.getInventoryName(i)
	if not inventory_name then goto get_inventory_sides_continue end
	inventory_sides[inventory_name] = i 
	::get_inventory_sides_continue::
end 
assert(inventory_sides["tile.crane_extractor"], "Attach an extractor to the rocket transport pad!")
assert(inventory_sides["tile.crane_inserter"], "Attach an inserter to the adapter that leads to the rocket transport pad's insertion point!")
assert(inventory_sides["tile.appliedenergistics2.BlockSpatialIOPort"], "Attach the Spatial I/O port to the adapter! Make sure it has its pylons and power, too!")

-- Now that the sides have been received, begin polling... (WHYYY!)
print("loading main")
local event = require("event")

local lock = false
local rocket_transport_side = inventory_sides["tile.crane_extractor"]
local rocket_transport_insert_side = inventory_sides["tile.crane_inserter"]
local spatial_io_side = inventory_sides["tile.appliedenergistics2.BlockSpatialIOPort"]
print("loading function")
-- Function called when player hits The Button.
-- Refer to Redstone I/O parameters for the parameters of this function.
local function transportPlayer(event_name, address, side_signalled, old_value, new_value, color)
	if not event_name then return end -- this is simply used to allow for this function to be directly called
	if old_value ~= 0 then return end -- needs no signal beforehand.
	if new_value == 0 then return end -- this probably shouldnt fire, BUT.. creepermusher17 REALLY likes quantum tunnelling my desh stamps into the ae2 network, so... he'll figure out a way to trigger this, too.
	if lock then return end -- impatient players...
	if table_length(detect_item(transposer, spatial_io_side, nil, true)) == 0 then return end -- there's no spatial i/o cell in 1st slot (or any), cancel.
	
	-- EMIT SIGNAL!! THE SHEER POWER OF THE SUN!!!! BLAST IT!!! *BOOM*
	while detect_item(transposer, spatial_io_side)[2] == nil do 
		spatial_io_signaller.setOutput({9001}) -- it's over 9000... i dont even watch DBZ, why am i making this reference..
		os.sleep(2) 
		spatial_io_signaller.setOutput({0}) 
	end
	-- once it has been detected (it BETTER be detected... lest it go into an infinite loop.), reset.
	spatial_io_signaller.setOutput({0})
	transposer.transferItem(spatial_io_side, rocket_transport_insert_side, 1, 2, 1) -- hopefully no one floods the insertion thing with hematite.
end
print("initializing event listener")

while true do -- (yes. the only cancellation is turning off the PC. CRY. about it.)
	transportPlayer(event.pull(0.1, "redstone_changed")) -- feeding args!! YUMMY!
	local item_detected = detect_item(transposer, rocket_transport_side, 9, true)
	if not item_detected or table_length(item_detected) == 0 then transportPlayer(event.pull(1, "redstone_changed")) goto main_loop_continue end
	print("payload!")
	-- PAYLOAD HAS ARRIVED!!! :DDDDDD
	lock = true
	
	for i = 10, transposer.getInventorySize(rocket_transport_side) do -- idiot proofing incase SOMEONE decides to put extra items into the extractor (Genius!)
		local transfer_item_return = transposer.transferItem(rocket_transport_side, spatial_io_side, 1, i, 1)
		print(transfer_item_return)
		if transfer_item_return ~= 0 then break end
	end
	-- Return the payload back into the material world.
	while detect_item(transposer, spatial_io_side)[2] == nil do 
		spatial_io_signaller.setOutput({9001}) -- it's over 9000... i dont even watch DBZ, why am i making this reference..
		os.sleep(2) 
		spatial_io_signaller.setOutput({0}) 
	end
	-- Once it has been detected on return, just move it back, ready for another button press!
	transposer.transferItem(spatial_io_side, spatial_io_side, 1, 2, 1)

	lock = false
	print("unlocking")
	::main_loop_continue::
end
