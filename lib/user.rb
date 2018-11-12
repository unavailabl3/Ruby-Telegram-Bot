class User
	def initialize(msg)
		@chat_id = msg['message']['chat']['id']
		@login = msg['message']['chat']['username']
	end

	def userChatId
		return @chat_id
	end

	def userLogin
		return @login
	end
end
