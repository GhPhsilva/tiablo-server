local callback = EventCallback()

function callback.monsterOnDropLoot(monster, corpse)
	EpicMonster.onDropLoot(monster, corpse)
end

callback:register()
