
local Class = require("aqua.util.Class")
local Node = require("aqua.util.Node")
local Observable = require("aqua.util.Observable")

local SelectNavigator = Class:new()

SelectNavigator.construct = function(self)
	local observable = Observable:new()
	self.observable = observable
	observable:add(self.view.controller)

	local noteChartSetList = Node:new()
	self.noteChartSetList = noteChartSetList
	noteChartSetList.selected = 1

	local noteChartList = Node:new()
	self.noteChartList = noteChartList
	noteChartList.selected = 1

	local scoreList = Node:new()
	self.scoreList = scoreList
	scoreList.selected = 1
end

SelectNavigator.scrollNoteChartSet = function(self, direction, destination)
	local noteChartSetList = self.noteChartSetList
	local noteChartList = self.noteChartList
	local scoreList = self.scoreList

	local noteChartSetItems = self.view.noteChartSetLibraryModel:getItems()

	direction = direction or destination - noteChartSetList.selected

	if not noteChartSetItems[noteChartSetList.selected + direction] then
		return
	end

	noteChartSetList.selected = noteChartSetList.selected + direction
	noteChartList.selected = 1
	scoreList.selected = 1

	local noteChartSetId = noteChartSetItems[noteChartSetList.selected].noteChartSetEntry.id
	self.view.noteChartLibraryModel:setNoteChartSetId(noteChartSetId)

	self:updateScore()

	self:send({
		name = "selectNoteChart",
		type = "noteChartSetEntry",
		id = noteChartSetId
	})
	self:send({
		name = "unloadModifiedNoteChart"
	})
end

SelectNavigator.scrollNoteChart = function(self, direction, destination)
	local noteChartList = self.noteChartList
	local noteChartItems = self.view.noteChartLibraryModel:getItems()

	direction = direction or destination - noteChartList.selected

	if not noteChartItems[noteChartList.selected + direction] then
		return
	end

	noteChartList.selected = noteChartList.selected + direction
	self:updateScore()
	local noteChartItem = noteChartItems[noteChartList.selected]

	self:send({
		name = "selectNoteChart",
		type = "noteChartEntry",
		noteChartEntryId = noteChartItem.noteChartEntry.id,
		noteChartDataEntryId = noteChartItem.noteChartDataEntry.id
	})
	self:send({
		name = "unloadModifiedNoteChart"
	})
end

SelectNavigator.updateScore = function(self)
	local noteChartList = self.noteChartList
	local noteChartItems = self.view.noteChartLibraryModel:getItems()
	local noteChartItem = noteChartItems[noteChartList.selected]
	self.view.scoreLibraryModel:setHash(noteChartItem.noteChartDataEntry.hash)
	self.view.scoreLibraryModel:setIndex(noteChartItem.noteChartDataEntry.index)
end

SelectNavigator.scrollScore = function(self, direction)
	local scoreList = self.scoreList
	local scoreItems = self.view.scoreLibraryModel:getItems()
	if not scoreItems[scoreList.selected + direction] then
		return
	end
	scoreList.selected = scoreList.selected + direction
end

SelectNavigator.updateSearch = function(self)
	local newSearchString = self.searchLineModel:getSearchString()
	if self.searchString == newSearchString then
		return
	end
	self.searchString = newSearchString

	local noteChartLibraryModel = self.view.noteChartLibraryModel
	local noteChartSetLibraryModel = self.view.noteChartSetLibraryModel

	local noteChartSetList = self.noteChartSetList
	local noteChartList = self.noteChartList

	local noteChartSetItems = self.view.noteChartSetLibraryModel:getItems()
	local noteChartItems = self.view.noteChartLibraryModel:getItems()

	local noteChartSetItem = noteChartSetItems[noteChartSetList.selected]
	local noteChartItem = noteChartItems[noteChartList.selected]

	noteChartLibraryModel:setSearchString(newSearchString)
	noteChartSetLibraryModel:setSearchString(newSearchString)

	noteChartLibraryModel:updateItems()
	noteChartSetLibraryModel:updateItems()

	self:scrollNoteChartSet(nil, noteChartSetLibraryModel:getItemIndex(noteChartSetItem))
	self:scrollNoteChart(nil, noteChartLibraryModel:getItemIndex(noteChartItem))
end

SelectNavigator.load = function(self)
	local observable = self.observable
	local noteChartSetList = self.noteChartSetList
	local noteChartList = self.noteChartList
	local scoreList = self.scoreList

	observable:add(self.view.controller)

	self.node = noteChartSetList
	noteChartSetList:on("up", function()
		self:scrollNoteChartSet(-1)
	end)
	noteChartSetList:on("down", function()
		self:scrollNoteChartSet(1)
	end)
	noteChartSetList:on("left", function()
		self.node = noteChartList
	end)

	noteChartList:on("up", function()
		self:scrollNoteChart(-1)
	end)
	noteChartList:on("down", function()
		self:scrollNoteChart(1)
	end)
	noteChartList:on("right", function()
		self.node = noteChartSetList
	end)
	noteChartList:on("left", function()
		self.node = scoreList
	end)
	noteChartList:on("return", function()
		self:send({
			action = "playNoteChart",
		})
	end)

	scoreList:on("up", function()
		self:scrollScore(-1)
	end)
	scoreList:on("down", function()
		self:scrollScore(1)
	end)
	scoreList:on("right", function()
		self.node = noteChartList
	end)

	self.searchString = self.searchLineModel:getSearchString()
end

SelectNavigator.unload = function(self)
	self.observable:remove(self.view.controller)
end

SelectNavigator.update = function(self)
	self:updateSearch()
end

SelectNavigator.setNode = function(self, nodeName)
	self.node = assert(self[nodeName])
end

SelectNavigator.call = function(self, ...)
	self.node:call(...)
end

SelectNavigator.send = function(self, event)
	return self.observable:send(event)
end

SelectNavigator.receive = function(self, event)
	if event.name == "wheelmoved" then
		local y = event.args[2]
		if y == 1 then
			self:call("up")
		elseif y == -1 then
			self:call("down")
		end
	elseif event.name == "mousepressed" then
		self:call("return")
	elseif event.name == "keypressed" then
		self:call(event.args[1])
	end
end

return SelectNavigator