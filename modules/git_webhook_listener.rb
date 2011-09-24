require 'sinatra/base'
class GitWebHookListener < Sinatra::Base
	configure do
		set :bind, :localhost
		set :port, 4567
		set :logging, true
		set :lock, true
	end

	get '/' do
		"This is devbot listening to webhooks"
	end
end

class GitWebhookPlugin < Cinch::BetterPlugin
	on :mention, /git/ do |msg|
		msg.reply "I'm tracking your git!"
	end
end

if @bot
	@bot.debug "Registering GitWebhookPlugin"
	@bot.better_plugins << GitWebhookPlugin.new(@bot)	
end
