$:.unshift "./lib"
require 'socket'
require 'json'
require_relative 'lib/chromiebara/protocol.rb'

class Wip
  def command
    [
      "/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome",
      "--headless",
      "--remote-debugging-pipe"
    ]
  end

  # // Enables remote debug over stdio pipes [in=3, out=4].
  def spawn_chrome
    command_read, command_write = IO.pipe
    output_read, output_write = IO.pipe

    @pid = Process.spawn(*command.map(&:to_s), 3 => command_read, 4 => output_write)

    command_read.close
    output_write.close

    sleep 5

    enable = Chromiebara::Protocol::Page.enable.merge(id: 0).to_json + "\0"
    puts enable
    puts command_write.write enable

    command = Chromiebara::Protocol::Page.navigate(url: "facebook.com").merge(id: 1).to_json + "\0"
    puts command
    puts command_write.write command
    puts output_read.read
  end
end
