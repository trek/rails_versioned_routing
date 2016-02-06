# Versioned Rails Routes

Versioned Rails Routes adds a set of conventions to the Rails Routing DSL
specfically designed to handle versioned HTTP APIs.

Versioned Rails Routes adds a `version` method to the Rails Routing DSL.

This extends Routing to limit positive route match results
to only requests for a HTTP verb/path combination that _also_
includes an `Accept` header specifiy a specific version.

Routes will match any requested version that is equal to or less than the provided version, allowing new versions to be frequently be added with minimal disruption to the public API.

Example:

```ruby
version(4) do
  # All requests to photos will match here for
  # version 4 only
  resources :photos
end

version(3) do
  # All requests to photos will match here for
  # version 3 only
  resources :photos
end

version(2) do
  # All requests to tweets will match here for
  # versions 4, 3, and 2
  resources :tweets

  # Requests to :videos will match here for
  # versions 4, 3, and 2.
  match "/videos(/:id')", via: :all, :to => proc {|env| [404, {}, ["Not Found"]] }
end

version(1) do
  # All requests to photos will match here for
  # versions 2 and 1.
  # versions 3, and 4 will match the route defined in version(3)
  resources :photos

  # All requests to photos will match here for
  # versions 4, 3, 2 and 1
  resources :articles

  # All requests to photos will match here for
  # versions 1 only
  # versions 2, 3, and 4 will match the route defined in version(2)
  resources :videos
end
```


### Defining Versioned Routes
Versioned routes are defined with the `version` method. `version` takes a block
and all routes defined in that block are limited to that version number (or higher)
unless the route is redefined at a higher version (see Fallthough Behavior), deprecated
(see Deprecating Routes In A Version).

The full routing API is available within the block. Calls to `resource(s)` will result in a
namespaced controller.


```ruby
version(5) do
  # the full routing API is available here.
  get 'some_action', controller: 'foo'

  # controller will be V5::TweetsController
  # locacated in controllers/v5/tweets_controller.rb
  resources :tweets
end
```

### Cascading Behavior
Requests for a verison match any routes declared with a verison number equal or less than the requested version.

Given the following routes:

```ruby
version(2) do
  resources :photos
end

version(1) do
  resources :friends
end
```

`GET` requests to '/friends' with an `Accept` header containing `version=2`
will cascade down to the the v1 `friends` resources.

This allows the v2 API to act as though it was defined like this:

```ruby
version(2) do
  resources :photos
  resources :friends
end
```

without the need for API consumres to know (or care) that the `:friends` resource
was not duplicated for v2.

Requests to the `:friends` resource, with an `Accept` header containing `version=1` will
`404` (there is no route defined in verison <= 1 that matches the route)

### Version Ordering
Requests for a verison match any routes with a verison number equal or less than the requested version.
To ensure matching occurs in the proper order, higher number versions must be delcared before lower number
versions


Good:

```ruby
version(2) do
  resources :photos
end

version(1) do
  resources :photos
end
```

You're gonna have a bad time:


```ruby
version(1) do
  resources :photos
end

version(2) do
  resources :photos
end
```

### Deprecating Routes In A Version
### Removing Old Versions

As such, route ordering precendence is important and higher
numbered versions *MUST* appear earlier in the route set to
correctly match.

Requests to :photos resources defined below where the
Accept header is `version=2` would incorrectly match
to the version `1` routes because the `1` is less than `2`.

```
version(1) do
  resources :photos
end

version(2) do
  resources :photos
end
```

Requests to :photos resources defined below where the
Accept header is `version=2` will correctly match
to the version `2` routes.

```
version(2) do
  resources :photos
end

version(1) do
  resources :photos
end
```


### Deprecating Older Versions
To

### Removing Older Versions

When an older version is no longer in use, you should delete the block
and move any routes not redefined in a higher version into the new lowest
defined version.

Given a routes definition where we'd like to remove v1:

```
version(3) do
  resources :photos
end

version(2) do
  resources :photos
end

version(1) do
  resources :friends
  resources :apartments
end
```

Requests to `/friends`  and `/apartments` for either v3 or v2 are falling through
to the definition for v1.

If `apartments` is being removed but `friends` is beign retained
with the removal of v1 redefine your routes like this:

```
version(3) do
  resources :photos
end

version(2) do
  resources :photos
  resources :friends, controller: 'v1/friends'
end
```

Alternatively, you could move all the files for `friends` from
the `v1` directory to the `v2` directory and avoid having to
provide a `controller` option.