--[[
    FormatNumber.lua
    FriendlyBiscuit
    Created on 05/15/2021 @ 22:25:03

    Description:
        Provides some basic and commonly-used number formatting functions.

    Documentation:
        <string> .AddCommas(input:number)
        -> Returns the input as a string formatted with correctly-placed commas.
        
        <string> .Shorten(input:number)
        -> Returns the input as a string shortened with the appropriate suffix.
        
        <string> .FormatCurrency(input:number)
        -> Returns the input as a string formatted with correctly-placed commas.
           Also attaches your chosen currency symbol as a prefix.
        
        <string> .FormatCurrencyShort(input:number)
        -> Returns the input as a string shortened with the appropriate suffix.
           Also attaches your chosen currency symbol as a prefix.
--]]

--= Root =--
local FormatNumber    = { }

--= Constants =--
local CURRENCY_SYMBOL = '$'

--= Functions =--
function FormatNumber.AddCommas(input: number): string
    return (tostring(math.modf(input)):reverse():gsub('(%d%d%d)', '%1,'):reverse()
           .. (tostring(input):match('%.%d+') or '')):gsub('^,', '')
end

function FormatNumber.Shorten(input: number): string
    local suffixes = { 'k', 'm', 'b', 't', 'q' }
    
	local i = math.floor(math.log(input, 1e3))
    local v = math.pow(10, i * 3)
    
	return ('%.1f'):format(input / v):gsub('%.?0+$', '') .. (suffixes[i] or '')
end

function FormatNumber.FormatCurrency(input: number): string
    return CURRENCY_SYMBOL .. FormatNumber.AddCommas(input)
end

function FormatNumber.FormatCurrencyShort(input: number): string
    return CURRENCY_SYMBOL .. FormatNumber.Shorten(input)
end

--= Return =--
return FormatNumber