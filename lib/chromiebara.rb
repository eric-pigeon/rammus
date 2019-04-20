require 'json'
require 'childprocess'
require 'capybara'

module Chromiebara
  require 'chromiebara/launcher'
  require 'chromiebara/protocol'
  require 'chromiebara/driver'
  require 'chromiebara/browser'
end


=begin
command = [
  "/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome",
  # "/Users/epigeon/Documents/Projects/Node/puppeteer/.local-chromium/mac-641577/chrome-mac/Chromium.app/Contents/MacOS/Chromium",
  '--disable-background-networking',
  '--enable-features=NetworkService,NetworkServiceInProcess',
  '--disable-background-timer-throttling',
  '--disable-backgrounding-occluded-windows',
  '--disable-breakpad',
  '--disable-client-side-phishing-detection',
  '--disable-default-apps',
  '--disable-dev-shm-usage',
  '--disable-extensions',
  '--disable-features=site-per-process,TranslateUI,BlinkGenPropertyTrees',
  '--disable-hang-monitor',
  '--disable-ipc-flooding-protection',
  '--disable-popup-blocking',
  '--disable-prompt-on-repost',
  '--disable-renderer-backgrounding',
  '--disable-sync',
  '--force-color-profile=srgb',
  '--metrics-recording-only',
  '--no-first-run',
  '--safebrowsing-disable-auto-update',
  '--enable-automation',
  '--password-store=basic',
  '--use-mock-keychain',
  '--headless',
  '--hide-scrollbars',
  '--mute-audio',
  "--headless",
  "--remote-debugging-port=0"
  # "--remote-debugging-pipe"
]

stderr_out, stderr_in = IO.pipe
_pid = Process.spawn(*command.map(&:to_s), 2 => stderr_in)
stderr_in.close

puts 'reading std err'
# puts stderr_out.read

ugh = ""
while(true)
  ugh += stderr_out.read(5).to_s
  puts ugh
end
=end


=begin
command_read, command_write = IO.pipe
output_read, output_write = IO.pipe

pid = Process.spawn(*command.map(&:to_s), 3 => command_read.fileno, 4 => output_write.fileno)

command_read.close
output_write.close


me = Chromiebara::Protocol::Target.create_target(url: 'about:blank').merge(id: 0).to_json + "\0"
puts me
puts command_write.write(me)

# puts "runetime enable"
# command_write.write(Chromiebara::Protocol::Runtime.enable.merge(id: 1).to_json + "\0")

enable = Chromiebara::Protocol::Page.enable.merge(id: 1).to_json + "\0"
puts enable
begin
  puts command_write.write(enable)
rescue => e
  puts e
end

dom = Chromiebara::Protocol::DOM.enable.merge(id: 4).to_json + "\0"
puts dom
puts command_write.write(dom)
#
# command = Chromiebara::Protocol::Page.navigate(url: "facebook.com").merge(id: 2).to_json + "\0"
# puts command
# puts command_write.write command

ugh = ""
while(true)
  ugh += output_read.read(5).to_s
  puts ugh
end
=end

