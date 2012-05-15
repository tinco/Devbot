class QuitterPlugin < Cinch::DynamicPlugin
	on :mention, /quit!/ do |msg|
		msg.reply "Alright, goodbye!"
		bot.quit("Goodbye cruel world!")
		bot.unload_plugins
	end
end

if @bot
	@bot.debug "QuitterPlugin"
	@bot.dynamic_plugins << QuitterPlugin.new(@bot)
end
