Utils = { }

Utils.Enumerate = function(netEnumerable)
	local enum = netEnumerable:GetEnumerator()
	return function()
		if enum:MoveNext() then
			return enum:get_Current()
		end
	end
end

Utils.FirstOrNil = function(netEnumerable, func)
	for item in Utils.Enumerate(netEnumerable) do
		if func(item) then
			return item
		end
	end
	return nil
end

Utils.Where = function(netEnumerable, func)
	local t = { }
	for item in Utils.Enumerate(netEnumerable) do
		if func(item) then
			table.insert(t, item)
		end
	end
	return t
end

Utils.TableToArray = function(luaTable)
	return _OpenRA.TableToArray(luaTable)
end