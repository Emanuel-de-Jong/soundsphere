local ModifierButton	= require("sphere.ui.ModifierMenu.ModifierButton")
local CheckboxButton	= require("sphere.ui.ModifierMenu.CheckboxButton")
local SliderButton		= require("sphere.ui.ModifierMenu.SliderButton")
local AddModifierButton	= require("sphere.ui.ModifierMenu.AddModifierButton")
local SequenceList		= require("sphere.ui.ModifierMenu.SequenceList")

local InconsequentialModifierButton = ModifierButton:new()

InconsequentialModifierButton.construct = function(self)
	local Modifier = self.item.Modifier
	local modifier = self.item.modifier

	local button
	if Modifier.inconsequential then
		if Modifier.variableType == "boolean" then
			button = CheckboxButton:new(self)
			button.item = self.item
			button.updateValue = function(self, value)
				self.list.menu.observable:send({
					name = "enableBooleanModifier",
					modifier = modifier,
					value = value
				})
			end
		elseif Modifier.variableType == "number" then
			button = SliderButton:new(self)
			button.item = self.item
			button.updateValue = function(self, value)
				self.list.menu.observable:send({
					name = "enableNumberModifier",
					modifier = modifier,
					value = value
				})

				SliderButton.updateValue(self, value)
			end
			button.removeModifier = function(self)
				self.list.menu.observable:send({
					name = "disableNumberModifier",
					modifier = modifier,
					Modifier = Modifier
				})
			end
		end
	elseif Modifier.sequential then
		button = AddModifierButton:new(self)
		button.item = self.item
		button.add = function(self)
			self.list.menu.observable:send({
				name = "addModifier",
				Modifier = Modifier
			})
			SequenceList:reloadItems()
		end
	end

	return button
end

return InconsequentialModifierButton
