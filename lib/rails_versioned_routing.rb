module RailsVersionedRouting
  VERSION = "1.0.0"

  class VersionConstraint
    attr_reader :version

    def initialize(options)
      @version = options.fetch(:version)
    end

    def matches?(request)
      accept = request.headers.fetch(:accept, '*/*')
      has_version = accept.match(/version=([\d+])/)

      if has_version
        version = has_version.captures.last.to_i
        return @version <= version
      else
        return @version == 1
      end
    end
  end

  def version(version_number, &routes)
    api_constraint = VersionConstraint.new(version: version_number)
    scope(module: "v#{version_number}", constraints: api_constraint, &routes)
  end
end
