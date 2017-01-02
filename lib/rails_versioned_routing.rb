require 'rails_versioned_routing/railtie' if defined?(Rails)

module RailsVersionedRouting
  VERSION = "1.2.0"

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
    class Visitor # :nodoc:
      DISPATCH_CACHE = {}

      def accept(node)
        visit(node)
      end

      private

        def visit node
          send(DISPATCH_CACHE[node.type], node)
        end

        def binary(node)
          visit(node.left)
          visit(node.right)
        end
        def visit_CAT(n); binary(n); end

        def nary(node)
          node.children.each { |c| visit(c) }
        end
        def visit_OR(n); nary(n); end

        def unary(node)
          visit(node.left)
        end
        def visit_GROUP(n); unary(n); end
        def visit_STAR(n); unary(n); end

        def terminal(node); end
        def visit_LITERAL(n); terminal(n); end
        def visit_SYMBOL(n);  terminal(n); end
        def visit_SLASH(n);   terminal(n); end
        def visit_DOT(n);     terminal(n); end

        private_instance_methods(false).each do |pim|
          next unless pim =~ /^visit_(.*)$/
          DISPATCH_CACHE[$1.to_sym] = pim
        end
    end

    class OptimizedPath < Visitor
      def accept(node)
        Array(visit(node))
      end

      private

      def visit_CAT(node)
        [visit(node.left), visit(node.right)].flatten
      end

      def visit_SYMBOL(node)
        node.left[1..-1].to_sym
      end

      def visit_STAR(node)
        visit(node.left)
      end

      def visit_GROUP(node)
        []
      end

      %w{ LITERAL SLASH DOT }.each do |t|
        class_eval %{ def visit_#{t}(n); n.left; end }, __FILE__, __LINE__
      end
    end

    def initialize(routes)
      @routes = routes
    end

    def grouped_by_version
      # `versions` is a hash whose empty value is
      # a new, nested hash.
      # The outer hash's keys will all be set to
      # version numbers.
      #
      # The value for each will be a hash.
      # The keys for the inner hash will be string key that
      # combines the routes path and HTTP method.
      #
      # Since higher numbered versions appear first
      # we can rely on the side effect of
      # those path/method pairs being already set
      # so we can safely avoid collisions.
      #
      # routes defined in *earlier* versions will appear
      # in each `versions[version_number]` hash unless
      # the current version has already set a matching
      # path/method key.
      versions = Hash.new {|h,k| h[k] = {}}

      @routes.each do |route|
        # routes that have a constraint added to them appear as
        # an rack 'application' of the type ActionDispatch::Routing::Mapper::Constraints
        if route.app.is_a?(ActionDispatch::Routing::Mapper::Constraints)

          # the constraint might not be a versioned constraint. We handle versioned constraint
          # rack apps different ly
          version_constraint = route.app.constraints.find {|constraint| constraint.is_a?(VersionConstraint) }

          # returns a string representation of the path by walking its
          # AST and building a string
          optimized_path = OptimizedPath.new.accept(route.path.spec)

          if version_constraint
            # transforms the variable names in path into a generic form so we can match the pattern
            # not the specific variable.
            # e.g.
            # get 'posts/:id/hello'
            # get 'posts/:post_id'/hello
            # would generate paths of
            # ['posts', :id, 'hello']
            # and
            # ['posts', :post_id, 'hello']
            # but the routing matching should treat them as
            # ['posts', ANY VARIABLE WE DONT CARE ABOUT NAME, 'hello']
            #
            # So, we transfrom all symbols into the same value
            denormalized_path = denormalize_path(optimized_path)

            # the full key for the hash is a combo of the path and the method
            # since the same path will match different controller/actions if
            # the HTTP method differs.
            denormalize_path_and_method = "#{denormalized_path}-#{route.constraints[:request_method]}"

            version = version_constraint.version

            # add to current version
            versions[version][denormalize_path_and_method] = route

            # add to higher versions unless higher version
            # already includes a path that matches
            versions.each do |k,v|
              next if k <= version

              versions[k][denormalize_path_and_method] ||= route
            end

          else
            versions[0][denormalize_path_and_method] = route
          end
        else
          versions[0][optimized_path] = route
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

  def removed
    @real_match = method(:match)

    # temporarily overrides `match` method in routes file
    def match(*args)
      @real_match.call(args[0], to: Proc.new { raise ActionController::RoutingError.new('Not Found') }, via: args[1][:via])
    end

    yield

    def match(*args)
      @real_match.call(*args)
    end
  end

  def self.group_by_version
    VersionedGroup.new(Rails.application.routes.routes).grouped_by_version
  end
end
