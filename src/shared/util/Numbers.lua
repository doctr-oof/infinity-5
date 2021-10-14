local Numbers = { }

function Numbers.AddCommas(n)
    return (tostring(math.modf(n)):reverse():gsub('(%d%d%d)', '%1,'):reverse() .. (tostring(n):match('%.%d+') or '')):gsub('^,', '')
end

function Numbers.ToSuffix(num)
    local suf = { 'K', 'M', 'B', 'T', 'Q' }
    
	local i = math.floor(math.log(num, 1e3))
    local v = math.pow(10, i * 3)
    
	return ('%.1f'):format(num / v):gsub('%.?0+$', '') .. (suf[i] or '')
end

function Numbers.FormatCreditsShort(num)
    return '$' .. Numbers.ToSuffix(num)
end

function Numbers.FormatCredits(num)
    return '$' .. Numbers.AddCommas(num)
end

return Numbers