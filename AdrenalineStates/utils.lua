
SYMBOL_CROSS = string.char(0xe2)..string.char(0x95)..string.char(0xb3)-- "\xE2\x95\xB3"
SYMBOL_SQUARE = string.char(0xe2)..string.char(0x96)..string.char(0xa1)-- "\xE2\x96\xA1"
SYMBOL_TRIANGLE = string.char(0xe2)..string.char(0x96)..string.char(0xb3)-- "\xE2\x96\xB3"
SYMBOL_CIRCLE = string.char(0xe2)..string.char(0x97)..string.char(0x8b)-- "\xE2\x97\x8B"

console.init()
console.clear(color.new(0,0,0,0))
--console.bgcolor(color.new(0,0,0,0))
function print(...) -- Hook a print to debug with console module :)
	console.print(string.format(...))
	console.render()
	screen.flip()
end

function newScroll(a,b,c)
	local obj = {ini=1,sel=1,lim=1,maxim=1,minim = 1}
	function obj:set(tab,mxn,modemintomin) -- Set a obj scroll
		obj.ini,obj.sel,obj.lim,obj.maxim,obj.minim = 1,1,1,1,1
		if(type(tab)=="number")then
			if tab > mxn then obj.lim=mxn else obj.lim=tab end
			obj.maxim = tab
		else
			if #tab > mxn then obj.lim=mxn else obj.lim=#tab end
			obj.maxim = #tab
		end
		if modemintomin then obj.minim = obj.lim end
	end
	function obj:max(mx)
		obj.maxim = #mx
	end
	function obj:up()
		if obj.sel>obj.ini then obj.sel=obj.sel-1
		elseif obj.ini-1>=obj.minim then
			obj.ini,obj.sel,obj.lim=obj.ini-1,obj.sel-1,obj.lim-1
		end
	end
	function obj:down()
		if obj.sel<obj.lim then obj.sel=obj.sel+1
		elseif obj.lim+1<=obj.maxim then
			obj.ini,obj.sel,obj.lim=obj.ini+1,obj.sel+1,obj.lim+1
		end
	end
	function obj:test(x,y,h,tabla,high,low,size)
		local py = y
		for i=obj.ini,obj.lim do 
			if i==obj.sel then screen.print(x,py,tabla[i],size,high)
			else screen.print(x,py,tabla[i],size,low)
			end
			py += h
		end
	end
	if a and b then
		obj:set(a,b,c)
	end
	return obj
end

-- Convert 4 bytes (32 bit) string to number int...
function str2int(str)
	local b1, b2, b3, b4 = string.byte(str, 1, 4)
	return (b4 << 24) + (b3 << 16) + (b2 << 8) + b1
end

-- Convert Number (32bit) to a string 4 bytes...
function int2str(data)
	return string.char((data)&0xff)..string.char(((data)>>8)&0xff)..string.char(((data)>>16)&0xff)..string.char(((data)>>24)&0xff)
end