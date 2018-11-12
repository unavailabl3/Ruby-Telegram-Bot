require 'faraday'
require 'uri'
require 'json'
require_relative 'inlinekeyboard'

class TelegramBot

	def initialize(bot_token:,proxy: '',stop_phrase: '/exit',exception_msg: 'Oops! Something goes wrong..',log: false)
		@api_url = "https://api.telegram.org/bot"
		@bot_token = bot_token;
		@proxy = proxy
		@stop_phrase = stop_phrase
		@exception_msg = exception_msg
		@log = log
		@users = {}
		@handlers = {}
		@opened_chats = {}
		@lastmsg = nil
	end

	def apiRequest(api_method,params=nil,log=@log,full=false)
		begin
			url_params = (params != nil) ? "?#{URI.encode_www_form(params)}" : ""
			if log==true
				puts "--------------API REQUEST URL----------------"
				puts "#{@api_url}#{@bot_token}/#{api_method}#{url_params}"
				puts "---------------------------------------------"
			end
			conn = Faraday.new(:url => "#{@api_url}#{@bot_token}/#{api_method}#{url_params}", :proxy => @proxy)
			response = JSON.parse(conn.get.body)
			return response if full == true
			return response["result"]
		rescue
			puts "RESCUE : #{api_method} , #{params} , #{log} , #{full}" if (log==true)
			sleep(1)
			self.apiRequest(api_method,params,log,full)
		end
	end
=begin
	def addUser(msg)
		chat_id = getChatId(msg)
		if !(@users.key?('chat_id'))
			new_user = User.new(msg)
			@users.store(chat_id, new_user)
			return new_user
		end
		return nil
	end
=end
	def toJSON(object)
		return JSON.generate(object)
	end

	def getUpdates(lastmsg: @lastmsg)
	    response = self.apiRequest('getUpdates',{:timeout => 0, :offset => (self.getUpdateId(lastmsg)+1)})
	    return response
	end

	def getUpdate(lastmsg: nil)
		updates = self.getUpdates()
		if updates.any?
			@lastmsg = lastmsg = self.lastUpdate(updates)
			opened_chat_id = getChatId(lastmsg)
			@opened_chats.store(opened_chat_id, getChatUsername(lastmsg)) if (@opened_chats[opened_chat_id] == nil)
			@lastmsg['callback_handler'] = lastmsg['callback_handler'] = ''
			if lastmsg.key?("callback_query")
				@lastmsg['callback_handler'] = lastmsg['callback_handler'] = self.callbackHandler(lastmsg['callback_query'])
			end
			self.turnOff() if (self.getMessageText(lastmsg) == @stop_phrase)
			return lastmsg
		end
	end

	def lastUpdate(updates)
		@lastmsg = updates[-1]
	    return @lastmsg
	end

	def getUpdateId(update)
		return 0 if update == nil
		return update["update_id"]
	end

	def getChatId(update)
		return update if !(update.is_a? Hash)
		return update['callback_query']['message']['chat']['id'] if (update.key?("callback_query"))
	    return update['message']['chat']['id'] if (update.key?("message"))
	    return update
	end

	def getChatUsername(update) 
		return nil if update == nil
		return update['callback_query']['from']['username'] if (update.key?("callback_query"))
	    return update['message']['from']['username']
	end	

	def chatType(update)
		return update['callback_query']['message']['chat']['type'] if (update.key?("callback_query"))
	    return update['message']['chat']['type']
	end

	def getMessageText(update)
		return '' if (update == nil)
		return update['callback_query']['message']['text'] if (update.key?("callback_query"))
		return update['message']['text']
	end

	def sendMessage(msg, text, parse_mode=nil, reply_markup=nil)
	    params = {:chat_id => getChatId(msg), :text => text, :parse_mode => parse_mode}
	    params.merge!({:reply_markup => JSON.generate(reply_markup.getHash)}) if (reply_markup != nil)
	    response = self.apiRequest('sendMessage', params)
		return response
	end

	def editMessage(msg_sent: nil, text: nil, parse_mode: 'html', reply_markup: '', params: nil)
		if (msg_sent != nil) && (text != nil)
			msg_sent = msg_sent['callback_query']['message'] if msg_sent.key?('callback_query')
			return self.apiRequest('editMessageText',{:chat_id => msg_sent['chat']['id'],:message_id => msg_sent['message_id'],:text => text,:parse_mode => parse_mode,:reply_markup => self.toJSON(reply_markup.getHash)})
		end
		if params != nil
			msg_sent = params['msg']['message']
			puts "MSGTOEDIT: #{msg_sent}" if (@log == true)
			return self.apiRequest('editMessageText',{:chat_id => msg_sent['chat']['id'],:message_id => msg_sent['message_id'],:text => params['text'],:parse_mode => params['parse_mode'],:reply_markup => self.toJSON(params['reply_markup'].getHash)})
		end
	end

	def shareToAll(text: nil, parse_mode: 'html', reply_markup: '', params: nil)
		@opened_chats.each do |key, value|
			if text != nil
				self.sendMessage(key, text, parse_mode, reply_markup)
			end
			if params != nil
				self.sendMessage(params['chat_id'], params['text'], params['parse_mode'], params['reply_markup'])  
			end
		end
	end

	def callbackHandler(callback)
		data = callback['data']
		puts "CALLBACK = #{callback['data']}" if (@log == true) 
		if(@handlers.key?(data))
			return data if (@handlers[data]['params'] == nil)
			@handlers[data]['params']['msg'] = callback
			puts "Handler : #{@handlers[data]}" if (@log == true)
			return (self.method(@handlers[data]['action'])).call(params: @handlers[data]['params'])
		end
		return nil
	end

	def getCallbackData(update)
		return update['callback_handler'] if (update != nil)
	end

	def getOpenedChats
		return @opened_chats
	end

	def newHandler(data: '',action: '',params: nil, replace: false)
		if (replace == true)
			@handlers.delete(data)
			return @handlers.store(data, {'action' => action,'params' => params})
		end
		return @handlers.store(data, {'action' => action,'params' => params}) if (@handlers[data] == nil)
	end

	def createInlineKeyboard
		return InlineKeyboard.new
	end

	def turnOff
		self.getUpdates()
		exit
	end
end
