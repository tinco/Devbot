require 'mechanize'
class TrelloPlugin < Cinch::DynamicPlugin
	def start
		@activities = []

		@trello = Mechanize.new
		@trello.post("https://trello.com/authenticate",
		 :user => "devbot@tinco.nl",
		 :password => "d3vb0t",
		 :returnUrl => '/')
		@checker = Thread.new do
			while true
				sleep 10
				fetch_new_data
			end
		end
	end

	def fetch_new_data
		@bot.debug "TrelloPlugin: fetching data"
		result = @trello.get "https://trello.com/data/board/4e7066e5fda81eaba2013dc1/current"
		if result #correct?
			new_data = JSON.parse result.body
			new_actions = new_data["actions"][0..2]
			while(activity = new_actions.shift != nil && activity["_id"] != @activities.last["_id"])
				@activities << activity
				announce activity
			end
		end
	end

	def announce(activity)
		msg = "\0033Trello: \0030 #{activity["type"]}"
		bot.channels.each do |c|
			c.send msg
		end
	end

	def destroy
		@checker.stop
	end
end

if @bot
	@bot.debug "TrelloPlugin"
	@bot.dynamic_plugins << TrelloPlugin.new(@bot)
end
