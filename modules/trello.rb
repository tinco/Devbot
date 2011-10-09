require 'mechanize'
class TrelloPlugin < Cinch::DynamicPlugin
	def start
		@activities = {}
		@members = {}
		@stopping = false


		@checker = Thread.new do
			while not @stopping
				fetch_new_data
				sleep 10
			end
		end
	end

	def init_trello
		begin
			@trello = Mechanize.new
			@trello.post("https://trello.com/authenticate",
						 :user => $config["trello"]["user"],
						 :password => $config["trello"]["password"],
						 :returnUrl => '/')
			true
		rescue
			@bot.debug "Could not initialize Trello connection"
			return false
		end
	end

	def fetch_new_data
		@bot.debug "TrelloPlugin: fetching data"
		return unless init_trello
		result = nil
		begin
			result = @trello.get "https://trello.com/data/board/#{$config["trello"]["board_id"]}/current"
		rescue => e
			@bot.debug "Encountered error while fetching: #{e.message}"
		end
		if result
			new_data = JSON.parse result.body

			new_actions = new_data["actions"][0..2]
			new_data["members"].each do |m|
				@members[m["_id"]] = m["fullName"]
			end

			while (activity = new_actions.pop)
				next if @activities[activity["_id"]]
				@activities[activity["_id"]] = activity
				announce activity
			end
		end
	end

	def announce(activity)
		y = lambda {|s| "\0037" + s + "\003"}
		g = lambda {|s| "\0033" + s + "\003"}
		e = lambda {|s| "\0030" + s + "\003"}

		member = @members[activity["idMemberCreator"]]
		msg = g["Trello: "] + e[member] + " "
		case activity["type"]
		when "updateCard"
			data = activity["data"]
			card_name = data["card"]["name"]
			if listbefore = data["listBefore"]
				msg += "moved card #{e[card_name]} from #{e[listBefore]} to #{e[data["listAfter"]]}"
			elsif old_name = data["old"]["name"]
				msg += "renamed card #{e[old_name]} to #{e[card_name]}"
			elsif data["old"]["pos"]
				msg += "reprioritized card #{e[card_name]}"
			else
				msg += "updated a card"
			end
		when "addMemberToBoard"
			msg += "added a member to the board"
		when "createBoardInvitation"
			msg += "invited someone to the board"	
		when "updateCheckItemStateOnCard"
			item = e[activity["data"]["checkItem"]["name"]]
			card_name = e[activity["data"]["card"]["name"]]
			status = g[activity["data"]["checkItem"]["state"]]
			msg += "marked item #{item} on card #{card_name} #{status}"
		when "createCard"
			msg += "created a card"
		when "addMemberToCard"
			msg += "added a member to a card"
			member = e[@members[activity["data"]["idMember"]]]
			card_name = e[activity["data"]["card"]["name"]]
			msg += "added #{member} to card #{card_name}"
		when "commentCard"
			text = activity["data"]["text"]
			card_name = activity["data"]["card"]["name"]
			msg += "commented #{e[text]} on card #{e[card_name]}"
		when "updateCheckItem"
			msg += "updated a checklist item"
		when "addChecklistToCard"
			msg += "added a checklist to a card"
		when "createChecklist"
			msg += "created a checklist"
		when "addAttachmentToCard"
			msg += "added an attachment to a card"
		when "removeChecklistFromCard"
			msg += "removed a checklist from a card"
		when "updateList"
			msg += "updated a list"
		else
			msg += "did something I don't understand (#{activity["type"]})"
		end
		@bot.channels.each do |c|
			c.send msg
		end
	end

	def destroy
		@stopping = true
	end
end

if @bot
	@bot.debug "TrelloPlugin"
	@bot.dynamic_plugins << TrelloPlugin.new(@bot)
end
