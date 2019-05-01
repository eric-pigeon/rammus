require 'sinatra/base'
require 'tilt/erb'
require 'rack'
require 'yaml'

class TestApp < Sinatra::Base
  get '/empty' do
  end
end
