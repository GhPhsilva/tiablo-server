local callback = EventCallback()

function callback.monsterOnSpawn(monster, position)
	if not monster then
		return
	end
	EpicMonster.onSpawn(monster, position)
end

callback:register()
