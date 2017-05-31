MEMORY_STICK_LOCATION_UX0 = 0
MEMORY_STICK_LOCATION_UR0 = 1
MEMORY_STICK_LOCATION_IMC0 = 2

local adrenaline_ms_root = "ux0:pspemu"

function AdrenalineLoadConfig()
	local fp = io.open("ux0:adrenaline/adrenaline.bin", "r+");
	if not fp then return nil end
	local magic1 = str2int(fp:read(4));
	fp:seek("set",20)
	local location = str2int(fp:read(4));
	fp:close()
	
	if location == MEMORY_STICK_LOCATION_UX0 then
		adrenaline_ms_root = "ux0:pspemu"
	elseif location == MEMORY_STICK_LOCATION_UR0 then
		adrenaline_ms_root = "ur0:pspemu"
	elseif location == MEMORY_STICK_LOCATION_IMC0 then
		adrenaline_ms_root = "imc0:pspemu"
	end
end

function getPspemuMemoryStickLocation()
	return adrenaline_ms_root;
end

ADRENALINE_SAVESTATE_MAGIC = 0x54535653

function set_version(path,ver)
	local fp = io.open(path,"r+")
	if not fp then return false end
	local magic = str2int(fp:read(4));
	if magic == ADRENALINE_SAVESTATE_MAGIC then
		fp:seek("set",4)
		fp:write(int2str(ver))
	end
	fp:close()
	return true;
end

MAX_STATES = 32
states = {} -- List empty

function initStates()
	local folder = string.format("%s/PSP/SAVESTATE", getPspemuMemoryStickLocation());
	print("Loading savestates %s\n",folder)
	local list = files.listfiles(folder)
	if list then
		for i=1, #list do
			print("#%d name: %s - ",i,list[i].name)
			if list[i].name:sub(1,5) == "STATE" then
				local slot = list[i].name:sub(6,7)
				print("Slot: %s ",tostring(slot))
				if slot and tonumber(slot) and tonumber(slot) < MAX_STATES then
					local fp = io.open(list[i].path ,"r+")
					local magic = str2int(fp:read(4));
					if magic == ADRENALINE_SAVESTATE_MAGIC then
						local entry = {}
						entry.num = tonumber(slot)
						fp:seek("set",4)
						entry.version = str2int(fp:read(4));
						local major = (entry.version >> 16) & 0xFF;
						local minor = (entry.version) & 0xFF;
						entry.version_str = string.format("%X.%X", major, minor)
						fp:seek("set",0x08)
						entry.title = fp:read(0x80)
						fp:seek("set",0x90)
						entry.screenshot_offset = str2int(fp:read(4));
						fp:seek("set",0x94)
						entry.screenshot_size = str2int(fp:read(4));
						entry.img = image.new(240,136,color.new(0,0,0))
						if entry.img then
							fp:seek("set",entry.screenshot_offset)
							entry.img:data(fp:read(entry.screenshot_size))
						end
						
						entry.mtime = list[i].mtime
						entry.size = list[i].size
						entry.path = list[i].path
						
						states[tonumber(slot)+1] = entry;
					end
					fp:close()
				end
			end
			print("\n")
		end
	end
end

AdrenalineLoadConfig() -- Get root!
initStates() -- Load states...

local scroll = newScroll(MAX_STATES, 3) -- MAX_STATES total spaces and 3 view spaces.
local back = image.load("back.png")
while true do
	buttons.read()
	if buttons.up or buttons.analogly < -60 then scroll:up() elseif buttons.down or buttons.analogly > 60 then scroll:down() end
	if buttons.cross and states[scroll.sel] then
		local new_major = osk.init("Major Version","4",2,1) -- v4.X
		local new_minor = osk.init("Minor Version","1",2,1) -- vX.1
		if new_major and tonumber(new_major) and new_minor and tonumber(new_minor) then
			new_major = tonumber(new_major)
			new_minor = tonumber(new_minor)
			local new_version = (new_major << 16) | (new_minor)
			if new_version != states[scroll.sel].version then
				if set_version(states[scroll.sel].path, new_version) then
					states[scroll.sel].version = new_version;
					states[scroll.sel].version_str = string.format("%X.%X", new_major, new_minor);
					os.message("Updated version of state!");
				end
			elseif new_version == states[scroll.sel].version then
				os.message("The state have the last version!");
			end
		end
	end
	if buttons.square and states[scroll.sel] then
		if os.message("Really wish delete this state?",1) == 1 then
			files.delete(states[scroll.sel].path)
			states[scroll.sel] = nil; -- remove state of list..
		end
	end
	if back then back:blit(0,0) end
	
	draw.fillrect(0,0,960,25,color.shadow)
	screen.print(10,5,string.format("Adrenaline States %X.%02X",APP_VERSION_MAJOR, APP_VERSION_MINOR),1,color.white)
	screen.print(950,5,string.format("%s - Batt: %s%%", os.date("%I:%M %p"), batt.lifepercent()),1,color.white,0x0,__ARIGHT) --FPS: %d - , screen.fps()
	
	local y = 35 + 5
	for i=scroll.ini,scroll.lim do
		if i == scroll.sel then draw.fillrect(0,y-5,960,136+10,color.shadow) end
		if states[i] then
			if states[i].img then
				states[i].img:blit(10,y)
			end
			screen.print(260,y,states[i].title)
			screen.print(260,y+20,states[i].mtime)
			
			screen.print(260, y+40,"V: "..states[i].version_str)
		else
			draw.fillrect(10,y,240,136, color.shine)
			draw.rect(10,y,240,136, color.white)
			screen.print(260,y,"Slot #"..(i-1).." Empty!")
		end
		
		y+= 158--136 + 10
	end
	
	draw.fillrect(0,544-25,960,25,color.shadow)
	screen.print(10,544-20,string.format("%s: Change Version state - %s: Delete state",SYMBOL_CROSS, SYMBOL_SQUARE),1,color.white)
	screen.flip()
end