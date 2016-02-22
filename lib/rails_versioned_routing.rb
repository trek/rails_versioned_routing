require 'rails_versioned_routing/railtie' if defined?(Rails)

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

  class VersionedGroup
    def initialize(routes)
      @routes = routes
    end

    def grouped_by_version
      # build a hash keyed version
      # each version is hash keyed on a path matcher
      # {
      #   1 => {
      #     'people/:VARIABLE' => <#Route>
      #     'people/' => <#Route>
      #   },
      #   2 => {
      #     'people/' => <#Route>
      #   }
      # }
      versions = Hash.new {|h,k| h[k] = {}}

      @routes.each do |route|
        if route.app.is_a?(ActionDispatch::Routing::Mapper::Constraints)
          version_constraint = route.app.constraints.find {|constraint| constraint.is_a?(VersionConstraint) }

          if version_constraint
            denormalized_path = denormalize_path(route.optimized_path)
            version = version_constraint.version
            # add to current version
            versions[version][denormalized_path] = route

            # add to higher versions unless higher version
            # already includes a path that matches
            versions.each do |k,v|
              next if k <= version

              versions[k][denormalized_path] ||= route
            end

          else
            versions[0][denormalized_path] = route
          end
        else
          versions[0][route.optimized_path] = route
        end
      end

      # flatten one level of the hash
      # {
      #   1 => [<#Route>, <#Route>],
      #   2 => [<#Route>]
      # }
      versions.each do |k,v|
        versions[k] = v.values
      end

      versions
    end

    def denormalize_path(path)
      path.map {|slug| slug.is_a?(Symbol) ? :VARIABLE : slug }
    end
  end

  def version(version_number, &routes)
    api_constraint = VersionConstraint.new(version: version_number)
    scope(module: "v#{version_number}", constraints: api_constraint, &routes)
  end

  def self.group_by_version
    VersionedGroup.new(Rails.application.routes.routes).grouped_by_version
  end
end
