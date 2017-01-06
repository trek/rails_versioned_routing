require 'test_helper'

class VersionedRoutingTest < ActionDispatch::IntegrationTest
  test "a request without a verison cascades to versionless routes" do
    get '/final_fallback'
    assert_equal(response.body, 'v0')
  end

  test "a route with an override will match on the higher verison" do
    get '/a_path_overridden_from_v1/somevalue/whats/anothervalue', {}, {'Accept' => 'version=2'}
    assert_equal(response.body, 'v2')
  end

  test "a route with an override will match on the lower verison if specified" do
    get '/a_path_overridden_from_v1/somevalue/whats/anothervalue', {}, {'Accept' => 'version=1'}
    assert_equal(response.body, 'v1')
  end

  test "a route not defined on a specific verison will cascade to until a lower version match is found" do
    get '/a_path_in_v2', {}, {'Accept' => 'version=3'}
    assert_equal(response.body, 'v2')
  end

  test "a route defined in a higher version will cascade on lower versions" do
    assert_raise ActionController::RoutingError do
      get '/a_path_only_in_v3', {}, {'Accept' => 'version=2'}
    end
  end

  test "a route removed in a version will return a 404" do
    get '/another_path_in_v1', {}, {'Accept' => 'version=1'}
    assert_equal(response.status, 200)

    assert_raise ActionController::RoutingError do
      get '/another_path_in_v1', {}, {'Accept' => 'version=2'}
    end
  end

  test "a route removed in a version lower than it self will return a 404" do
    get '/another_path_in_v1', {}, {'Accept' => 'version=1'}
    assert_equal(response.status, 200)

    assert_raise ActionController::RoutingError do
      get '/another_path_in_v1', {}, {'Accept' => 'version=3'}
    end
  end

  test "a route that hasn't been deprecated in a version will not return a Warning Header" do
    get '/a_path_in_v1_deprecated', {}, {'Accept' => 'version=1'}
    assert_equal(response.status, 200)
    assert_equal(response.headers['X-Deprecated-Endpoint'], nil)
  end

  test "a route deprecated in a version will return a Warning Header" do
    get '/a_path_in_v1_deprecated', {}, {'Accept' => 'version=2'}
    assert_equal(response.status, 200)
    assert_equal(response.headers['X-Deprecated-Endpoint'], 'This endpoint will be removed in an upcoming api version.')
  end

  test "a route that hasn't been deprecated in a version lower than it self will return Warning Header" do
    get '/a_path_in_v1_deprecated', {}, {'Accept' => 'version=3'}
    assert_equal(response.status, 200)
    assert_equal(response.headers['X-Deprecated-Endpoint'], 'This endpoint will be removed in an upcoming api version.')
  end
end
