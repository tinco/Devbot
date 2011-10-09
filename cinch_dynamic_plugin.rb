module Cinch
	class DynamicBot < Bot
		attr_accessor :dynamic_plugins

		def initialize(&b)
			super(&b)
			@dynamic_plugins = []
		end

		def unload_plugins
			@dynamic_plugins.each do |p|
				p.destroy
			end
			@dynamic_plugins = []
		end

		def load_plugins
			begin
				Dir[File.dirname(__FILE__) + '/modules/*.rb'].each do |plugin|
					load plugin
				end
				dynamic_plugins.each(&:start)
				return true
			rescue LoadError
				return false
			end
		end

		def reload_plugins
			unload_plugins
			load_plugins
		end
	end

	class DynamicPlugin
		def self.on(event, regexps = [], *args, &block)
			regexps = [*regexps]
			regexps = [//] if regexps.empty?
			@handlers ||= []
			@handlers << [event, regexps, args, block]	
		end

		attr_accessor :bot

		def initialize(bot)
			@bot = bot
			handlers = self.class.instance_variable_get(:@handlers)
			handlers ||= []
			handlers.each do |event, regexps, args, block|
				on event, regexps, args, &block
			end	
		end

		def start
		end

		def destroy
			handlers = @handlers.each do |h|
				h.stop
			end.collect
			@bot.handlers.unregister *handlers
			self.class.instance_variable_set(:@handlers, nil)
		end

		# Registers a handler.
		def on(event, regexps = [], *args, &block)
			regexps = [*regexps]
			regexps = [//] if regexps.empty?

			event = event.to_sym

			@handlers ||= []

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
				@handlers << handler
				@bot.handlers.register handler
			end

			return @handlers
		end	
	end
end
