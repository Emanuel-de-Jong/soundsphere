local AudioFactory		= require("aqua.audio.AudioFactory")
local AudioContainer	= require("aqua.audio.Container")
local Class				= require("aqua.util.Class")
local Observable		= require("aqua.util.Observable")
local sound				= require("aqua.sound")
local Config			= require("sphere.config.Config")
local SoundNoteFactory	= require("sphere.screen.gameplay.AudioEngine.SoundNoteFactory")

local AudioEngine = Class:new()

AudioEngine.construct = function(self)
	self.observable = Observable:new()

	self.localAliases = {}
	self.globalAliases = {}
end

AudioEngine.timeRate = 1

AudioEngine.load = function(self)
	self.backgroundContainer = AudioContainer:new()
	self.foregroundContainer = AudioContainer:new()
	
	self.backgroundContainer:setVolume(Config:get("volume.global") * Config:get("volume.music"))
	self.foregroundContainer:setVolume(Config:get("volume.global") * Config:get("volume.effects"))
end

AudioEngine.update = function(self)
	self.backgroundContainer:update()
	self.foregroundContainer:update()
end

AudioEngine.unload = function(self)
	self.backgroundContainer:stop()
	self.foregroundContainer:stop()
end

AudioEngine.receive = function(self, event)
	if event.name == "LogicalNoteState" then
		local soundNote = SoundNoteFactory:getNote(event.note)
		soundNote.audioEngine = self
		return soundNote:receive(event)
	elseif event.name == "TimeState" then
		self.currentTime = event.exactCurrentTime
		self:setTimeRate(event.timeRate)
	end
end

AudioEngine.playAudio = function(self, paths, layer, keysound, stream)
	if not paths then return end
	for i = 1, #paths do
		local path = paths[i][1]
		local audio
		local aliases = self.localAliases
		if not keysound and not aliases[path] then
			aliases = self.globalAliases
		end
		if not stream or not Config:get("audio.stream") then
			audio = AudioFactory:getStreamMemory(aliases[paths[i][1]])
		else
			audio = AudioFactory:getStreamMemory(aliases[paths[i][1]])
		end
		if audio then
			audio.offset = self.currentTime
			audio:setRate(self.timeRate)
			audio:setBaseVolume(paths[i][2])
			if layer == "background" then
				self.backgroundContainer:add(audio)
			elseif layer == "foreground" then
				self.foregroundContainer:add(audio)
			end
			audio:play()
		end
	end
end

AudioEngine.setTimeRate = function(self, timeRate)
	if timeRate == 0 and self.timeRate ~= 0 then
		self.backgroundContainer:pause()
		self.foregroundContainer:pause()
	elseif timeRate ~= 0 and self.timeRate == 0 then
		self.backgroundContainer:setRate(timeRate)
		self.foregroundContainer:setRate(timeRate)
		self.backgroundContainer:play()
		self.foregroundContainer:play()
	else
		self.backgroundContainer:setRate(timeRate)
		self.foregroundContainer:setRate(timeRate)
	end
	self.timeRate = timeRate
end

AudioEngine.getPosition = function(self)
	return self.backgroundContainer:getPosition()
end

AudioEngine.setPosition = function(self, position)
	self.backgroundContainer:setPosition(position)
	self.foregroundContainer:setPosition(position)
end

return AudioEngine
