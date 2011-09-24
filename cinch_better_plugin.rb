module Cinch
	class BetterBot < Bot
		attr_accessor :better_plugins

		def initialize(&b)
			super(&b)
			@better_plugins = []
		end

	    def dispatch_to_plugins(event, msg = nil, *arguments)
			@better_plugins.each do |p|
				p.dispatch(event, msg, *arguments)
			end
		end
	end

	class BetterPlugin
		def self.on(event, regexps = [], *args, &block)
			regexps = [*regexps]
			regexps = [//] if regexps.empty?
			@handlers ||= []
			@handlers << [event, regexps, args, block]	
		end

		def initialize(bot)
			@bot = bot
			@handlers = HandlerList.new
			self.class.instance_variable_get(:@handlers).each do |event, regexps, args, block|
				on(event, regexps, *args, &block)	
			end	
		end

	    def dispatch(event, msg = nil, *arguments)
			@handlers.dispatch(event, msg, *arguments)
		end

		# Registers a handler.
		def on(event, regexps = [], *args, &block)
			regexps = [*regexps]
			regexps = [//] if regexps.empty?

			event = event.to_sym

			handlers = []

			regexps.each do |regexp|
				pattern = case regexp
						  when Pattern
							  regexp
						  when Regexp
							  Pattern.new(nil, regexp, nil)
						  else
							  if event == :ctcp
								  Pattern.new(/^/, /#{Regexp.escape(regexp.to_s)}(?:$| .+)/, nil)
							  else
								  Pattern.new(/^/, /#{Regexp.escape(regexp.to_s)}/, /$/)
							  end
						  end
				@bot.debug "[on handler] Registering handler with pattern `#{pattern.inspect}`, reacting on `#{event}`"
				handler = Handler.new(@bot, event, pattern, args, &block)
				handlers << handler
				@handlers.register(handler)
			end

			return handlers
		end	
	end
end
