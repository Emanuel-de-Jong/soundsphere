local SearchManager = {}

SearchManager.search = function(self, list, searchString)
	local foundList = {}
	for i = 1, #list do
		if self:check(list[i], searchString) then
			foundList[#foundList + 1] = list[i]
		end
	end
	return foundList
end

SearchManager.check = function(self, entry, searchString)
	for _, searchSubString in ipairs(searchString:split(" ")) do
		local key, operator, value = searchSubString:match("^(.-)([=><~!]+)(.+)$")
		if key and self:checkFilter(entry, key, operator, value) or self:find(entry, searchSubString) then
			-- skip
		else
			return false
		end
	end
	return true
end

local fieldList = {
	"hash",
	"artist",
	"title",
	"name",
	"source",
	"tags",
	"creator",
	"inputMode"
}

SearchManager.find = function(self, entry, searchSubString)
	for i = 1, #fieldList do
		local value = entry[fieldList[i]]
		if value and value:lower():find(searchSubString:lower(), 1, true) then
			return true
		end
	end
end

SearchManager.checkTag = function(self, entry, value)
	if value == "played" then
		local scores = self.scoreModel:getScoreEntries(entry.hash, entry.index)
		if scores then
			return value
		end
	end
end

SearchManager.checkFilter = function(self, entry, key, operator, value)
	local value1 = tonumber(entry[key])
	local value2 = tonumber(value)

	if not value1 or not value2 then
		local entryKey
		if key ~= "tag" then
			entryKey = tostring(entry[key])
		else
			entryKey = self:checkTag(entry, value)
		end
		return self:checkFilterString(entryKey, tostring(value), operator)
	end
	
	return self:checkFilterNumber(value1, value2, operator)
end

SearchManager.checkFilterString = function(self, value1, value2, operator)
	if operator == "=" or operator == "==" then
		return value1 == value2
	elseif operator == "!=" or operator == "~=" then
		return value1 ~= value2
	end
end

SearchManager.checkFilterNumber = function(self, value1, value2, operator)
	if operator == "=" or operator == "==" then
		return value1 == value2
	elseif operator == ">" then
		return value1 > value2
	elseif operator == "<" then
		return value1 < value2
	elseif operator == ">=" then
		return value1 >= value2
	elseif operator == "<=" then
		return value1 <= value2
	elseif operator == "!=" or operator == "~=" then
		return value1 ~= value2
	end
end

return SearchManager
