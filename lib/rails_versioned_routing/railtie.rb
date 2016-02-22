module RailsVersionedRouting
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/rails_versioned_routing_tasks.rake'
    end
  end
end