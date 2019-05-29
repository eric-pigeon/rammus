require 'sinatra/base'
require 'tilt/erb'
require 'rack'
require 'yaml'

class TestApp < Sinatra::Base
  get '/empty' do
  end

  get '/timeout-img.png' do
    sleep 1
  end

  get '/http-cookie' do
    response.set_cookie 'http_cookie', value: 'test-cookie', http_only: true
    ''
  end
end
