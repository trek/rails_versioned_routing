require 'rails_versioned_routing'

Dummy::Application.routes.draw do
  extend RailsVersionedRouting

  beta! do
    get 'a_path_overridden_from_v1/:id/whats/:ok', controller: 'sample', action: 'a_path_overridden_from_v1'
    get 'a_path_only_in_beta', controller: 'sample'
  end

  version(3) do
    post 'a_path_only_in_v3', controller: 'sample', action: 'posted_a_path_only_in_v3'
    get 'a_path_only_in_v3', controller: 'sample'
  end

  version(2) do
    get 'a_path_overridden_from_v1/:id/whats/:ok', controller: 'sample', action: 'a_path_overridden_from_v1'
    get 'a_path_in_v2', controller: 'sample'

    removed do
      get 'another_path_in_v1', controller: 'sample'
    end
  end

  version(1) do
    get 'a_path_in_v1', controller: 'sample'
    get 'another_path_in_v1', controller: 'sample'
    get 'a_path_overridden_from_v1/:id/whats/:ok', controller: 'sample', action: 'a_path_overridden_from_v1'
  end

  get 'final_fallback', controller: 'sample'
end
