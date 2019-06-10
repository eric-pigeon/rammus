require 'sinatra/base'
require 'support/sinatra_authorization'
require 'tilt/erb'
require 'rack'
require 'yaml'

class TestApp < Sinatra::Base
  set :protection, except: :frame_options
  helpers do
    include Sinatra::Authorization::Helpers
  end

  get '/empty' do
  end

  get '/timeout-img.png' do
    sleep 1
  end

  get '/http-cookie' do
    response.set_cookie 'http_cookie', value: 'test-cookie', http_only: true
    ''
  end

  get '/foo-header' do
    response.set_header 'foo', 'bar'
  end

  get '/empty-redirect' do
    redirect '/empty'
  end

  get '/protected' do
    protect! username: 'user', password: 'pass', realm: 'Restriced Area'
    "This is protected by basic auth"
  end
end
