module RailsVersionedRouting
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      @status, @headers, @response = @app.call(env)

      if env['deprecated_endpoint']
        @headers.merge!('X-Deprecated-Endpoint' => 'This endpoint will be removed in an upcoming api version.')
      end

      [@status, @headers, @response]
    end
  end
end
