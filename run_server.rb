$LOAD_PATH << File.expand_path("../spec", __FILE__)
$LOAD_PATH << File.expand_path("../lib", __FILE__)
require 'concurrent'
require 'chromiebara/promise'
require 'support/test_server'
require 'byebug'
TestServer.start!

TestServer.set_content_security_policy('/empty.html', 'script-src http://localhost:4567')
#require 'support/test_app'
#TestApp.start!
