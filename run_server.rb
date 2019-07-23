$LOAD_PATH << File.expand_path("../spec", __FILE__)
$LOAD_PATH << File.expand_path("../lib", __FILE__)
require 'concurrent'
require 'chromiebara/promise'
require 'support/test_server'
require 'byebug'

#TestServer.instance.set_route '/empty.html' do |req, res|
#  res.status = 204
#  res.finish
#end

TestServer.start_ssl!
