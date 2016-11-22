local sensor = peripheral.wrap("bottom")
local chest = peripheral.wrap("left");
local mon;
local currentDest = "Unknown"

function resetMonitor()
	mon.setTextScale(0.5)
	mon.setBackgroundColor( colors.white )
	mon.setTextColor( colors.green )
	mon.setCursorPos(1,1)
	mon.clear()
end

function deployMonitor()
	local success, blockInfo = turtle.inspectUp();
	if success and string.find(blockInfo.name, "quartz") then
		turtle.select(4)
		turtle.digUp()
		turtle.select(5)
		if turtle.placeUp() then
			mon = peripheral.wrap("top")
			resetMonitor()
		else
			write("Failed to place monitor")
		end
	end
end

function retractMonitor()
	local success, blockInfo = turtle.inspectUp();
	if success and string.find(blockInfo.name, "ComputerCraft") then
		turtle.select(5)
		turtle.digUp()
		turtle.select(4)
		if turtle.placeUp() then
		else
			write("failed to place quartz")
		end
	end
	mon = nil
end

function safeGetPlayerData(player_name)
	local info
	pcall( function() info = sensor.getPlayerByName(player_name) end)
	return info
end

local player_on_pad = false;
local player_blocking_mon = false;

function doScan()
	player_on_pad = false;
	player_blocking_mon = false;
	
	for i, detected_player in pairs(sensor.getPlayers()) do
		local player_name = detected_player.name
		local player_info = safeGetPlayerData(player_name)
		if player_info then
			local pos = player_info.basic().position;
			if -0.01 > pos.z and pos.z > -1 and 0 < pos.x and pos.x <= 1 and pos.y == 3 then
				player_on_pad = true
			end
			if pos.z >= 0                   and 0 < pos.x and pos.x <= 1 and pos.y == 3 then
				player_blocking_mon = true;
			end
		end
	end
end

function getFirstEmptySlotNum()
	local chestSize = chest.getInventorySize()
	for i = 1,chestSize do
		local stackInfo = chest.getStackInSlot(i)
		if not stackInfo then
			return i
		end
	end
end

function retractBook()
	local firstEmpty = getFirstEmptySlotNum()
	if not firstEmpty then
		print("cant find empty slot in chest")
		os.exit()
	end
	chest.pullItem("down", 1, 1, firstEmpty)
	currentDest = "Deactivated"
end

function writeAt(s, x, y, textColor, lineColor)
	if not textColor then textColor = colors.green; end
	if not lineColor then lineColor = colors.white; end
	mon.setCursorPos(x, y)
	mon.setBackgroundColor( lineColor )
	mon.setTextColor( textColor )
	mon.clearLine()
	mon.write(s)
end

function showMenu()
	resetMonitor()
	writeAt("   Current:", 1,1, colors.black, colors.green)
	writeAt(currentDest, 1, 2)
	writeAt("  Choose new:", 1, 3, colors.black, colors.green)
	for i = 1,7 do
		local bookInfo = chest.getStackInSlot(i)
		local bookName = ""
		if bookInfo and bookInfo.myst_book then
			bookName = string.sub(bookInfo.display_name, 1, 14);
		end
		writeAt(bookName, 1, i+3)
	end
end

local serviceCount = 0;
function serviceMenu()
	-- writeAt("" .. serviceCount, 7, 10);
	serviceCount = serviceCount + 1
	
	local x, y = getClickWithTimeout(0.5)
	if x then
		-- writeAt("" .. x .. ", " .. y .. "         ", 1, 10)
		if  y > 3 then
			local bookNum = y-3
			local bookInfo = chest.getStackInSlot(bookNum)
			if bookInfo and bookInfo.myst_book then
				local newDestName = string.sub(bookInfo.display_name, 1, 14);
				mon.clear();
				writeAt("Setting Portal", 1, 1, color.black, color.green);
				writeAt("   Dest To:", 1, 2, color.black, color.green);
				writeAt(newDestName, 1, 4)
				
				retractBook()
				if chest.pushItem("down", bookNum, 1, 1) then
					currentDest = newDestName;
					mon.setTextScale(3)
					mon.setBackgroundColor(colors.green)
					mon.setTextColor( colors.black)
					writeAt(" OK", 1, 2);
					sleep(2)
					showMenu()
					return
				else
					print("failed to push book " .. bookInfo.display_name .. " in slot " .. bookNum .. " to portal")
					writeAt("ERROR!", 1, 7)
				end
			end
		end
		-- showMenu()
		-- writeAt("" .. x .. ", " .. y .. "         ", 1, 9)
	else
		-- writeAt("noclick", 1, 10)
	end
end

function getClickWithTimeout(timeout)
	local timerid = os.startTimer(timeout)
	while true do
		local event, a, b, c = os.pullEvent()
		if event == "monitor_touch" then
			return b, c
		end
		if event == "timer" and a == timerid then
			break
		end
	end
end

retractMonitor()
retractBook()

local retractDelay = 5;
local needsleep = true;

while true do
	doScan()
	
	if not mon then
		if player_on_pad and not player_blocking_mon then
			deployMonitor()
			showMenu()
		end
	end
	
	if mon then
		if player_on_pad then
			retractDelay = 5
			serviceMenu()
		else
			if not player_blocking_mon then
				retractDelay = retractDelay - 1;
				if retractDelay < 0 then
					retractMonitor()
				end
				sleep(.5)
			end
		end
	end
end
