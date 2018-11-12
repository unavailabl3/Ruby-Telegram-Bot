class InlineKeyboard
	@buttons = nil

	def initialize
		@buttons = []
	end

	def addButton(text:,url:'',callback_data:'',switch_inline_query:'',switch_inline_query_current_chat:'')
		@buttons.push(['text' => text,'url' => url,'callback_data' => callback_data,'switch_inline_query' => switch_inline_query,'switch_inline_query_current_chat' => switch_inline_query_current_chat])
	end

	def getHash
		return {:inline_keyboard => @buttons}
	end
end
