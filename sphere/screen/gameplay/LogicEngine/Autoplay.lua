local Autoplay = {}

Autoplay.processNote = function(self, note)
	if note.noteType == "ShortNote" then
		return self:processShortNote(note)
	elseif note.noteType == "SoundNote" then
		return self:processSoundNote(note)
	elseif note.noteType == "LongNote" then
		return self:processLongNote(note)
	end
end

Autoplay.processShortNote = function(self, note)
	local deltaTime = note.startNoteData.timePoint.absoluteTime - note.logicEngine.currentTime
	if deltaTime <= 0 then
		local layer
		if note.noteType ~= "SoundNote" then
			-- note.noteHandler:clickKey()
			layer = "foreground"
		else
			layer = "background"
		end
		note.noteHandler:send({
			name = "KeyState",
			state = true,
			note = note,
			layer = layer
		})
		
		note.keyState = true
		
		note:process("exactly")
		note.score:processShortNoteState(note.state)
		
		if note.ended then
			note.score:hit(0, note.startNoteData.timePoint.absoluteTime)
		end
	end
end

Autoplay.processSoundNote = function(self, note)
	if note.pressSounds and note.pressSounds[1] then
		if note.startNoteData.timePoint.absoluteTime <= note.logicEngine.currentTime then
			note.noteHandler:send({
				name = "KeyState",
				state = true,
				note = note,
				layer = "background"
			})
		else
			return
		end
	end
	
	note.state = "skipped"
	return note:next()
end

Autoplay.processLongNote = function(self, note)
	local deltaStartTime = note.startNoteData.timePoint.absoluteTime - note.logicEngine.currentTime
	local deltaEndTime = note.endNoteData.timePoint.absoluteTime - note.logicEngine.currentTime
	
	local nextNote = note:getNext()
	if deltaStartTime <= 0 and not note.keyState then
		local layer
		if note.noteType ~= "SoundNote" then
			-- note.noteHandler:switchKey(true)
			layer = "foreground"
		else
			layer = "background"
		end
		note.noteHandler:send({
			name = "KeyState",
			state = true,
			note = note,
			layer = layer
		})
		
		note.keyState = true
		
		note:process("exactly", "none")
		note.score:processLongNoteState("startPassedPressed", "clear")
		
		if note.started and not note.judged then
			note.score:hit(0, note.startNoteData.timePoint.absoluteTime)
			note.judged = true
		end
	elseif deltaEndTime <= 0 and note.keyState or nextNote and nextNote:isHere() then
		local layer
		if note.noteType ~= "SoundNote" then
			-- note.noteHandler:switchKey(false)
			layer = "foreground"
		else
			layer = "background"
		end
		note.noteHandler:send({
			name = "KeyState",
			state = false,
			note = note,
			layer = layer
		})
		
		note.keyState = false
		
		note:process("none", "exactly")
		note.score:processLongNoteState("endPassed", "startPassedPressed")
	end
end

return Autoplay
