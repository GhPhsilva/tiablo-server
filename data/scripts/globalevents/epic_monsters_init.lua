local epicInit = GlobalEvent("EpicMonstersInit")

function epicInit.onStartup()
	EpicMonster.loadConfig()
	logger.info("Epic monsters system loaded with config: {}", EpicMonster.config.title)
end

epicInit:register()
