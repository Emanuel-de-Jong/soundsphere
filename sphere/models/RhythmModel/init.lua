local Class				= require("aqua.util.Class")
local Observable		= require("aqua.util.Observable")
local ScoreEngine		= require("sphere.models.RhythmModel.ScoreEngine")
local LogicEngine		= require("sphere.models.RhythmModel.LogicEngine")
local GraphicEngine		= require("sphere.models.RhythmModel.GraphicEngine")
local AudioEngine		= require("sphere.models.RhythmModel.AudioEngine")
local TimeEngine		= require("sphere.models.RhythmModel.TimeEngine")
local InputManager		= require("sphere.models.RhythmModel.InputManager")
local ReplayModel		= require("sphere.models.ReplayModel")
local ModifierModel		= require("sphere.models.ModifierModel")

local RhythmModel = Class:new()

RhythmModel.construct = function(self)
	local modifierModel = ModifierModel:new()
	local inputManager = InputManager:new()
	local replayModel = ReplayModel:new()
	local timeEngine = TimeEngine:new()
	local scoreEngine = ScoreEngine:new()
	local audioEngine = AudioEngine:new()
	local logicEngine = LogicEngine:new()
	local graphicEngine = GraphicEngine:new()

	self.modifierModel = modifierModel
	self.inputManager = inputManager
	self.replayModel = replayModel
	self.timeEngine = timeEngine
	self.scoreEngine = scoreEngine
	self.audioEngine = audioEngine
	self.logicEngine = logicEngine
	self.graphicEngine = graphicEngine

	timeEngine.observable:add(audioEngine)
	timeEngine.observable:add(scoreEngine)
	timeEngine.observable:add(logicEngine)
	timeEngine.observable:add(graphicEngine)
	timeEngine.observable:add(replayModel)
	timeEngine.observable:add(inputManager)
	timeEngine.logicEngine = logicEngine
	timeEngine.audioEngine = audioEngine

	logicEngine.observable:add(modifierModel)
	logicEngine.observable:add(audioEngine)
	logicEngine.scoreEngine = scoreEngine

	modifierModel.timeEngine = timeEngine
	modifierModel.scoreEngine = scoreEngine
	modifierModel.audioEngine = audioEngine
	modifierModel.graphicEngine = graphicEngine
	modifierModel.logicEngine = logicEngine

	scoreEngine.timeEngine = timeEngine

	audioEngine.timeEngine = timeEngine

	graphicEngine.logicEngine = logicEngine

	inputManager.observable:add(logicEngine)
	inputManager.observable:add(replayModel)

	replayModel.observable:add(inputManager)
	replayModel.timeEngine = timeEngine
	replayModel.logicEngine = logicEngine

	local observable = Observable:new()
	self.observable = observable

	timeEngine.observable:add(observable)
	scoreEngine.observable:add(observable)
	logicEngine.observable:add(observable)
	inputManager.observable:add(observable)
	graphicEngine.observable:add(observable)
end

RhythmModel.load = function(self)
end

RhythmModel.unload = function(self)
	self.timeEngine:unload()
	self.logicEngine:unload()
	self.scoreEngine:unload()
	self.graphicEngine:unload()
	self.audioEngine:unload()
end

RhythmModel.receive = function(self, event)
	self.timeEngine:receive(event)
	self.modifierModel:receive(event)
	self.inputManager:receive(event)
end

RhythmModel.update = function(self, dt)
	self.replayModel:update()
	self.logicEngine:update()
	self.audioEngine:update()
	self.scoreEngine:update()
	self.graphicEngine:update(dt)
	self.modifierModel:update()
end

RhythmModel.setNoteChart = function(self, noteChart)
	assert(noteChart)
	self.modifierModel.noteChart = noteChart
	self.timeEngine.noteChart = noteChart
	self.scoreEngine.noteChart = noteChart
	self.logicEngine.noteChart = noteChart
	self.graphicEngine.noteChart = noteChart
end

RhythmModel.setNoteSkin = function(self, noteSkin)
	self.graphicEngine.noteSkin = noteSkin
end

RhythmModel.setInputBindings = function(self, inputBindings)
	assert(inputBindings)
	self.inputManager:setBindings(inputBindings)
end

RhythmModel.setResourceAliases = function(self, localAliases, globalAliases)
	self.audioEngine.localAliases = localAliases
	self.audioEngine.globalAliases = globalAliases
	self.graphicEngine.localAliases = localAliases
	self.graphicEngine.globalAliases = globalAliases
end

RhythmModel.setVolume = function(self, layer, value)
	if layer == "global" then
		self.audioEngine.globalVolume = value
	elseif layer == "music" then
		self.audioEngine.musicVolume = value
	elseif layer == "effects" then
		self.audioEngine.effectsVolume = value
	end
	self.audioEngine:updateVolume()
end

RhythmModel.setAudioMode = function(self, layer, value)
	if layer == "primary" then
		self.audioEngine.primaryAudioMode = value
	elseif layer == "secondary" then
		self.audioEngine.secondaryAudioMode = value
	end
end

return RhythmModel
