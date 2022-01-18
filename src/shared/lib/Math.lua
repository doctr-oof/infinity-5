--[[
       __  ___     __  __
      /  |/  /__ _/ /_/ /
     / /|_/ / _ `/ __/ _ \
    /_/  /_/\_,_/\__/_//_/
    By FriendlyBiscuit
    01/18/2022 @ 13:34:01
    
    Description:
        Provides a set of utility math functions that are not included in the default Roblox
        math library.
        
        Based of Quenty's math module.
    
    Documentation:
        No documentation provided.
--]]

--= Module Root =--
local Math = { }

--= Functions =--
function Math.Map(input: number, min0: number, max0: number, min1: number, max1: number): number
	if max0 == min0 then
		error('Cannot map inputs with a range of zero.', 2)
	end
    
	return (((input - min0)*(max1 - min1)) / (max0 - min0)) + min1
end

function Math.StaticMap(input: number, min1: number, max1: number): number
	return (((input - 0)*(max1 - min1)) / (1 - 0)) + min1
end

function Math.Lerp(num0: number, num1: number, percent: number): number
    return num0 + ((num1 - num0) * percent)
end

function Math.LawOfCos(a: number, b: number, c: number): number|nil
	local l = (a*a + b*b - c*c) / (2 * a * b)
	local angle = math.acos(l)
    
	if angle ~= angle then
		return nil
	end
    
	return angle
end

function Math.Round(number: number, precision: number): number
	if precision then
		return math.floor((number/precision) + 0.5) * precision
	else
		return math.floor(number + 0.5)
	end
end

function Math.RoundUp(number: number, precision: number): number
	return math.ceil(number/precision) * precision
end

function Math.RoundDown(number: number, precision: number): number
	return math.floor(number/precision) * precision
end

--= Casing Support =--
Math.map = Math.Map
Math.staticMap = Math.StaticMap
Math.lerp = Math.Lerp
Math.lawOfCos = Math.LawOfCos
Math.round = Math.Round
Math.roundUp = Math.RoundUp
Math.roundDown = Math.RoundDown

--= Return Module =--
return Math