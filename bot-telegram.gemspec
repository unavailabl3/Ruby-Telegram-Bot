$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'bot-telegram'
  s.version     = '1.0.1'
  s.date        = '2018-11-12'
  s.summary     = 'TelegramBot - Simple gem for working with Telegram API with proxy option'
  s.description = 'Simple gem for working with Telegram API under ruby. Can work with proxy or without.'
  s.author      = 'Nikolay AV'
  s.email       = 'tranebest97@gmail.com'
  s.homepage    = 'https://github.com/unavailabl3/Ruby-Telegram-Bot'
  s.license     = 'MIT'
  s.files       = `git ls-files`.split("\n")
  s.add_dependency('faraday', '~> 0', '>= 0')
  s.add_dependency('json', '~> 1.5.5', '>= 1.5.5')
end
