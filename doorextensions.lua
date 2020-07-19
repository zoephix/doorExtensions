PLUGIN.name = "Door Extensions"
PLUGIN.author = "Zoephix"
PLUGIN.desc = "A extension for the doors plugin, adding easy commands that target every door."

local PLUGIN = PLUGIN

-- Variables for the door data.
local variables = {
	"disabled",
	"noSell",
	"hidden"
}

function PLUGIN:callOnDoorChildren(entity, callback)
	local parent

	if (entity.nutChildren) then
		parent = entity
	elseif (entity.nutParent) then
		parent = entity.nutParent
	end

	if (IsValid(parent)) then
		callback(parent)
		
		for k, v in pairs(parent.nutChildren) do
			local child = ents.GetMapCreatedEntity(k)

			if (IsValid(child)) then
				callback(child)
			end
		end
	end
end

nut.command.add("doorsetunownableall", {
	adminOnly = true,
	onRun = function(client, arguments)
		-- Get every door entity
		for _, entity in pairs(ents.GetAll()) do
			-- Validate it is a door.
			if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
				-- Set it so it is unownable.
				entity:setNetVar("noSell", true)

				PLUGIN:callOnDoorChildren(entity, function(child)
					child:setNetVar("noSell", true)
                end)
                
                PLUGIN:SaveDoorData()
			end
		end

		-- Tell the player they have made the doors unownable.
		client:notify("You have made every door unownable.")
	end
})

nut.command.add("doorsetownableall", {
	adminOnly = true,
	onRun = function(client, arguments)
		-- Get every door entity
		for _, entity in pairs(ents.GetAll()) do
			-- Validate it is a door.
			if (IsValid(entity) and entity:isDoor() and !entity:getNetVar("disabled")) then
				-- Set it so it is ownable.
				entity:setNetVar("noSell", nil)

				PLUGIN:callOnDoorChildren(entity, function(child)
					child:setNetVar("noSell", nil)
                end)
                
                PLUGIN:SaveDoorData()
			end
		end

		-- Tell the player they have made the doors ownable.
		client:notify("You have made every door ownable.")
	end
})

nut.command.add("doorsetdisabledall", {
	adminOnly = true,
	syntax = "<bool disabled>",
	onRun = function(client, arguments)
		local disabled = util.tobool(arguments[1] or true)

		-- Get every door entity
		for _, entity in pairs(ents.GetAll()) do
			-- Validate it is a door.
			if (IsValid(entity) and entity:isDoor()) then

				-- Set it so it is ownable.
				entity:setNetVar("disabled", disabled)

				PLUGIN:callOnDoorChildren(entity, function(child)
					child:setNetVar("disabled", disabled)
                end)
                
                PLUGIN:SaveDoorData()
			end
		end

		-- Tell the player they have made the doors (un)disabled.
		if (disabled) then
			client:notify("You have disabled every door.")
		else
			client:notify("You have undisabled every door.")
		end
	end
})

nut.command.add("doorsethiddenall", {
	adminOnly = true,
	syntax = "<bool hidden>",
	onRun = function(client, arguments)
		local hidden = util.tobool(arguments[1] or true)

		-- Get every door entity
		for _, entity in pairs(ents.GetAll()) do
			-- Validate it is a door.
			if (IsValid(entity) and entity:isDoor()) then

				entity:setNetVar("hidden", hidden)
				
				PLUGIN:callOnDoorChildren(entity, function(child)
					child:setNetVar("hidden", hidden)
                end)
                
                PLUGIN:SaveDoorData()
			end
		end

		-- Tell the player they have made the doors (un)disabled.
		if (hidden) then
			client:notify("You have hidden every door.")
		else
			client:notify("You have unhidden every door.")
		end
	end
})

if (SERVER) then
	-- Called after the entities have loaded.
	function PLUGIN:LoadData()
		-- Restore the saved door information.
		local data = self:getData()

		if (!data) then return end

		-- Loop through all of the saved doors.
		for k, v in pairs(data) do
			-- Get the door entity from the saved ID.
			local entity = ents.GetMapCreatedEntity(k)

			-- Check it is a valid door in-case something went wrong.
			if (IsValid(entity) and entity:isDoor()) then
				-- Loop through all of our door variables.
				for k2, v2 in pairs(v) do
					if (k2 == "children") then
						entity.nutChildren = v2

						for index, _ in pairs(v2) do
							local door = ents.GetMapCreatedEntity(index)

							if (IsValid(door)) then
								door.nutParent = entity
							end
						end
					else
						entity:setNetVar(k2, v2)
					end
				end
			end
		end
	end

	-- Called before the gamemode shuts down.
	function PLUGIN:SaveDoorData()
		-- Create an empty table to save information in.
		local data = {}
		local doors = {}

		for k, v in ipairs(ents.GetAll()) do
			if (v:isDoor()) then
				doors[v:MapCreationID()] = v
			end
		end

		local doorData

		-- Loop through doors with information.
		for k, v in pairs(doors) do
			-- Another empty table for actual information regarding the door.
			doorData = {}

			-- Save all of the needed variables to the doorData table.
			for k2, v2 in ipairs(variables) do
				local value = v:getNetVar(v2)

				if (value) then
					doorData[v2] = v:getNetVar(v2)
				end
			end
			
			-- Add the door to the door information.
			if (table.Count(doorData) > 0) then
				data[k] = doorData
			end
		end
		self:setData(data)
	end
end