require 'mechanize'
class TrelloPlugin < Cinch::DynamicPlugin
	def start
		@activities = []
		@members = {}

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
			new_data["members"].each do |m|
				@members[m["_id"]] = m["fullName"]
			end

			while((activity = new_actions.shift) && @activities.last.nil? ||
				   (@activities.last && activity["_id"] !=
									   @activities.last["_id"]))
				@activities << activity
				announce activity
			end
		end
	end

	def announce(activity)
		begin
		@bot.debug @members.to_s
		@bot.debug activity
		member = @members[activity["idMemberCreator"]]
		msg = "\0033Trello: \0030#{member}\003 "
		case activity["type"]
		when "updateCard"
			msg += "updated a card"
		when "addMemberToBoard"
			msg += "added a member to the board"
		when "createBoardInvitation"
			msg += "invited someone to the board"	
		when "updateCheckItemStateOnCard"
			msg += "updated a checklist on a card"
		when "createCard"
			msg += "created a card"
		when "addMemberToCard"
			msg += "added a member to a card"
		when "commentCard"
			msg += "commented on a card"
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
			msg += "did something I don't understand (#{activity["type"]}"
		end
		@bot.channels.each do |c|
			c.send msg
		end
		rescue => e
			puts "e ---- #{e.message}"
		end
	end

	def destroy
		@checker.exit
	end
end

if @bot
	@bot.debug "TrelloPlugin"
	@bot.dynamic_plugins << TrelloPlugin.new(@bot)
end
