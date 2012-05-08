# curb_threadpool

A multi-threaded worker pool for Curb.

## Usage

    ct = Curl::ThreadPool.new
    10000.times { |i| ct[i] = "http://localhost/test" }
    responses = ct.perform() # => contains keyed response hash

or

    ct = Curl::ThreadPool.new
    reqs = []
    10000.times { reqs << "http://localhost/test" }
    ct.get(reqs) # => contains responses in same order as reqs

In order to re-use connections opened by the pool, hang on to it:

    Thread.current[:my_pool] ||= Curl::ThreadPool.new
    Thread.current[:my_pool].get("http://localhost/test")

This way, if you frequently make requests to the same host (e.g., an API
service) then the connections will be kept open as long as possible and
re-used, speeding up your response time. Curl will automatically
reconnected when necessary.

## Contributing to curb_threadpool

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012 Chetan Sarva. See LICENSE for further details.
