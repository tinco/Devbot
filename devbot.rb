require 'yaml'

require 'rubygems'
require 'bundler/setup'

require 'cinch'
require './cinch_dynamic_plugin'

config_file = "config.yml"
if not File.exists? config_file
  puts "Can't find config file #{config_file}"
  exit
end

$config = YAML.load_file config_file

@bot = Cinch::DynamicBot.new do
	configure do |c|
		c.nick = $config["nick"] || "devbot-test"
		c.port = $config["port"] || 6660
		c.server = $config["server"] || "irc.xs4all.nl"
		c.channels = $config["channels"] || ["#devbot.test"]
	end

	on :message, /#{nick}/ do |m|
		bot.handlers.dispatch :mention, m
	end

	on :mention, /hello/ do |m|
		m.reply "Hello, #{m.user.nick}"
	end

	on :mention, /reload/ do |m|
		m.reply("You're not the boss of me!") and next if not m.channel.opped? m.user
		m.reply "Reloading plugins.."
		if bot.reload_plugins
			m.reply "Succesfully reloaded modules!"
		else	
			m.reply "Sorry, I couldn't reload, #{m.user.nick} :("
		end
	end
end

@bot.load_plugins
@bot.start
