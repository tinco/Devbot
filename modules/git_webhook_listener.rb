require 'sinatra/base'
require 'json'

class GitWebhookListener < Sinatra::Base
	configure do
		set :bind, :localhost
		set :port, 4567
		set :logging, true
		set :lock, true
	end

	get '/' do
		settings.bot.channels.each do |c|
			c.send "Someone visited my homepage"
		end
		"This is devbot listening to webhooks really closely!"
	end

	# Next method taken from http://github.com/thedjinn/gitbot and might
	# be slightly modified to fit the mood.

	<<-EOL
		Copyright (c) 2010 Emil Loer

		Permission is hereby granted, free of charge, to any person obtaining
		a copy of this software and associated documentation files (the
		"Software"), to deal in the Software without restriction, including
		without limitation the rights to use, copy, modify, merge, publish,
		distribute, sublicense, and/or sell copies of the Software, and to
		permit persons to whom the Software is furnished to do so, subject to
		the following conditions:

		The above copyright notice and this permission notice shall be
		included in all copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
		NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
		LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
		OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
		WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	EOL

	post "/git" do
		p params[:payload]
		push = JSON.parse(params[:payload])

		repo = push["repository"]["name"]
		branch = push["ref"].gsub(/^refs\/heads\//,"")

		# sort commits by timestamp
		push["commits"].sort! do |a,b|
			ta = tb = nil
			begin
				ta = DateTime.parse(a["timestamp"])
			rescue ArgumentError
				ta = Time.at(a["timestamp"].to_i)
			end

			begin
				tb = DateTime.parse(b["timestamp"])
			rescue ArgumentError
				tb = Time.at(b["timestamp"].to_i)
			end

			ta <=> tb
		end

		# output first 3 commits
		push["commits"][0..2].each do |c|
			say repo, "\0030#{repo}:\0037 #{branch}\0033 #{c["author"]["name"]}\003 #{c["message"]}"
		end

		if push["commits"].length-2 > 0
			say repo, "\0030#{repo}:\0037 #{branch}\003 ... and #{push["commits"].length-2} more"
		end

		push.inspect
	end

	def say(repo, message)
		settings.bot.channels.each do |c|
			c.send message
		end
	end

	attr_accessor :bot
end

class GitWebhookPlugin < Cinch::DynamicPlugin
	attr_accessor :server

	on :mention, /git/ do |msg|
		msg.reply "I'm tracking your git!"
	end

	def initialize(bot)
		super(bot)
		GitWebhookListener.set :bot, bot
	end

	def start
		plugin = self
		t = Thread.new do
			GitWebhookListener.run! do |server|
				plugin.server = server
			end
		end
	end

	def destroy
		begin
			GitWebhookListener.quit! server, "GitWebhookPlugin"
		rescue
			@bot.debug "Hopefully it worked, I threw an error"
		end
		super
	end	
end

if @bot
	@bot.debug "Registering GitWebhookPlugin"
	@bot.dynamic_plugins << GitWebhookPlugin.new(@bot)	
end
