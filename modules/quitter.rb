class QuitterPlugin < Cinch::DynamicPlugin

	on :mention, /quit!/ do |msg|
		msg.reply "OK, goodbye!"
		bot.unload_plugins
		bot.quit("Goodbye cruel world!")
	end
end

if @bot
	@bot.debug "QuitterPlugin"
	@bot.dynamic_plugins << QuitterPlugin.new(@bot)
end
