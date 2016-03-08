require 'test_helper'

class VersionedRoutingTest < ActionDispatch::IntegrationTest
  def names(version)
    routes = RailsVersionedRouting.group_by_version
    routes[version].map(&:defaults)
  end

  test "version contains routes defined within version" do
    assert(names(3).include?({:controller=>"v3/sample", :action=>"a_path_only_in_v3"}))
  end

  test "version contains routes defined within version if the HTTP method differs" do
    assert(names(3).include?({:controller=>"v3/sample", :action=>"posted_a_path_only_in_v3"}))
  end

  test "version does not contains routes defined in later version" do
    assert(!names(2).include?({:controller=>"v3/sample", :action=>"a_path_only_in_v3"}))
  end

  test "version contains routes defined in earlier version" do
    assert(names(3).include?({:controller=>"v2/sample", :action=>"a_path_in_v2"}))
    assert(names(3).include?({:controller=>"v1/sample", :action=>"a_path_in_v1"}))
  end

  test "version does not contain routes overridden in earlier version" do
    assert(!names(3).include?({:controller=>"v1/sample", :action=>"a_path_overridden_from_v1"}))
    assert(!names(2).include?({:controller=>"v1/sample", :action=>"a_path_overridden_from_v1"}))
  end
end