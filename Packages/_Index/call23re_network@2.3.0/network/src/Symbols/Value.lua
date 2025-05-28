local Value = newproxy(true)
getmetatable(Value).__tostring = function()
	return "<Network.Value>"
end
return Value