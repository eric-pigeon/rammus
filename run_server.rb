$LOAD_PATH << "/Users/epigeon/Documents/Projects/Ruby/chromiebara/spec"
require 'support/test_server'
require 'byebug'
TestServer.start!

TestServer.set_content_security_policy('/empty.html', 'script-src http://localhost:4567')
#require 'support/test_app'
#TestApp.start!
