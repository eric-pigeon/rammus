# frozen_string_literal: true

$LOAD_PATH << File.expand_path("../spec", __FILE__)
$LOAD_PATH << File.expand_path("../lib", __FILE__)
require 'concurrent'
require 'rammus/promise'
require 'support/test_server'
require 'byebug'
TestServer.start!
