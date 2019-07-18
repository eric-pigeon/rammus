require 'rack'
require "zlib"

class TestServer
  include Chromiebara::Promise::Await
  HANDLER = Rack::Handler.get('puma')
  HANDLER_NAME = "puma"
  SERVER_SETTINGS = {:Port=>4567, :Host=>"localhost"}
  STATIC_PATH = File.dirname(__FILE__) + "/public"
  CONTENT_SECURITY_POLICY = 'Content-Security-Policy'.freeze
  LAST_MODIFIED = 'Last-Modified'.freeze

  RequestSubscriber = Struct.new(:promise, :resolve, :reject)

  def self.running_server
    @running_server
  end

  def self.running_server=(server)
    @running_server = server
  end

  def self.instance
    @_instance ||= new
  end

  def self.start!
    HANDLER.run instance, SERVER_SETTINGS do |server|
      port = SERVER_SETTINGS[:Port]
      $stderr.puts "== TestServer running on #{port}"

      self.running_server = server
    end
  end

  def self.stop!
    return if running_server.nil?

    running_server.respond_to?(:stop!) ? running_server.stop! : running_server.stop
    $stderr.puts "Test server done"

    self.running_server = nil
  end

  def self.set_content_security_policy(path, policy)
    @_content_security_policy[path] = policy
  end

  def initialize
    @_routes = {}
    @_auths = {}
    @_request_subscribers = {}
    @_gzip_routes = Set.new
    @_content_security_policy = {}
    @_cached_path_prefix = STATIC_PATH + "/cached"
    @_start_time = Time.now
  end

  def call(env)
    request = Request.new env
    response = Response.new

    path = request.path

    if @_auths.has_key? path
      expected_auth = @_auths[path]
      auth = Rack::Auth::Basic::Request.new env
      unless auth.provided? && auth.basic? && auth.credentials == expected_auth
        response.status = 401
        response.header['WWW-Authenticate'] = 'Basic realm="Secure Area"'
        response.write 'HTTP Error 401 Unauthorized: Access is denied'
        return response.finish
      end
    end
    if subscriber = @_request_subscribers.delete(path)
      subscriber.resolve.(request)
    end

    if handler = @_routes[path]
      handler.call request, response
    else
      serve_file request, response, path
    end
  end

  def wait_for_request(path)
    promise = @_request_subscribers[path]

    return promise unless promise.nil?

    subscriber = RequestSubscriber.new(*Chromiebara::Promise.create)

    @_request_subscribers[path] = subscriber

    subscriber.promise
  end

  def set_route(path, &block)
    @_routes[path] = block
  end

  def hang_route(path)
    promise, resolve, _reject = Chromiebara::Promise.create

    @_routes[path] = ->(req, res) do
      await promise.then { |response| res.finish }, 0
    end

    resolve
  end

  def set_redirect(from, to)
    set_route from do |req, res|
      res.redirect to
      res.finish
    end
  end

  def set_auth(path, username, password)
    @_auths[path] = [username, password]
  end

  def enable_gzip(path)
    @_gzip_routes << path
  end

  def set_content_security_policy(path, policy)
    @_content_security_policy[path] = policy
  end

  def reset
    @_routes.clear
    @_auths.clear
    @_gzip_routes.clear
    @_content_security_policy.clear
    @_request_subscribers.each do |_path, subscriber|
      subscriber.reject.("Server has been reset")
    end
    @_request_subscribers.clear
  end

  private

    def serve_file(request, response, path)
      path = "/index.html" if path == "/"

      file_path = STATIC_PATH + path

      if !@_cached_path_prefix.nil? && file_path.start_with?(@_cached_path_prefix)
        if request.env['HTTP_IF_MODIFIED_SINCE']
          response.status = 304
          return response.finish
        end
        response.headers[Rack::CACHE_CONTROL] =  'public, max-age=31536000'
        response.headers[LAST_MODIFIED] = @_start_time.httpdate
      else
        response.header[Rack::CACHE_CONTROL] = 'no-cache, no-store'
      end
      if policy = @_content_security_policy[path]
        response.header[CONTENT_SECURITY_POLICY] = policy
      end

      data =
        begin
          File.read file_path
        rescue => _err
          response.status = 404
          response.write "File not found #{file_path}"
          return response.finish
        end

      mime_type = Rack::Mime.mime_type File.extname file_path
      is_text_encoding = /^text|^application\/(javascript|json)/.match? mime_type
      content_type = is_text_encoding ? "#{mime_type}; charset=utf-8" : mime_type
      response.header[Rack::CONTENT_TYPE] = content_type

      if @_gzip_routes.include? path
        response.headers['Content-Encoding'] = 'gzip'
        response.write Zlib.gzip data
        response.finish
      else
        response.write data
        response.finish
      end
    end

  class Request
    include Rack::Request::Helpers
    include Rack::Request::Env

    def headers
      @_headers = Headers.new self
    end

    def method
      headers['REQUEST_METHOD']
    end

    def post_body
      body.string
    end
  end

  class Headers
    def initialize(request)
      @request = request
    end

    def [](key)
      @request.get_header env_name key
    end

    private

      HTTP_HEADER = /\A[A-Za-z0-9-]+\z/
      CGI_VARIABLES = Set.new(%W[
        AUTH_TYPE
        CONTENT_LENGTH
        CONTENT_TYPE
        GATEWAY_INTERFACE
        HTTPS
        PATH_INFO
        PATH_TRANSLATED
        QUERY_STRING
        REMOTE_ADDR
        REMOTE_HOST
        REMOTE_IDENT
        REMOTE_USER
        REQUEST_METHOD
        SCRIPT_NAME
        SERVER_NAME
        SERVER_PORT
        SERVER_PROTOCOL
        SERVER_SOFTWARE
      ]).freeze

      # Converts an HTTP header name to an environment variable name if it is
      # not contained within the headers hash.
      def env_name(key)
        key = key.to_s
        if key =~ HTTP_HEADER
          key = key.upcase.tr("-", "_")
          key = "HTTP_" + key unless CGI_VARIABLES.include?(key)
        end
        key
      end

  end

  class Response < Rack::Response
    def initialize
      super
      @_chunked_queue = nil
    end

    def set_chunked_response!
      @_chunked_queue = Queue.new
      set_header Rack::TRANSFER_ENCODING, CHUNKED
      [ChunkedBodyWriter.new(@_chunked_queue), [status.to_i, header, ChunkedBodyProxy.new(@_chunked_queue)]]

    end
  end

  class ChunkedBodyWriter
    def initialize(queue)
      @queue = queue
    end

    def write(chunk)
      @queue << chunk
    end
    alias :<< :write

    def finish
      @queue.close
    end
    alias :end :finish
  end

  class ChunkedBodyProxy
    TERM = "\r\n"
    TAIL = "0#{TERM}#{TERM}"

    def initialize(queue)
      @queue = queue
    end

    def each
      while chunk = @queue.pop
        size = chunk.bytesize
        next if size == 0

        chunk = chunk.b
        yield [size.to_s(16), TERM, chunk, TERM].join
      end
      yield TAIL
    end
  end
end
