
require "curb"

# A multi-threaded worker pool for Curb
module Curl
class ThreadPool

  class Request
    # methods supported: :delete, :get, :head, :post, :put
    attr_accessor :key, :uri, :body, :method
    def initialize(key, uri, method=:get, body=nil)
      @key    = key
      @uri    = uri
      @method = method
      @body   = body
    end
  end

  attr_reader :reqs, :results

  def initialize(size=4)
    @size = size
    reset()
  end

  # Shorthand for adding requests
  def add(req)
    @reqs << req
  end
  alias_method :<<, :add

  # Wait for all threads to complete
  def join
    @threads.each { |t| t.join }
    @threads.clear
  end

  # Close all active Curl connections
  def close
    if @clients then
      @clients.each { |c| c.reset(); c.close() }
    end
  end

  # Reset the ThreadPool
  def reset
    close()
    @reqs = []
    @results = {}
    @clients = []
    @threads = []
    @size.times{ @clients << Curl::Easy.new }
  end

  # Send multiple get requests
  #
  # @param [Array<String>] urls   list of URLs
  #
  # @return [Array] array of response bodies
  def get(urls)
    if urls.nil? or urls.empty? then
      return []
    end

    urls = [urls] if not urls.kind_of? Array
    urls.each_with_index do |url, i|
      @reqs << Request.new(i, url.to_s)
    end

    return collate_results(perform())
  end

  # Send multiple post requests
  #
  # @param [Array] reqs
  def post(reqs)
    if reqs.nil? or reqs.empty? then
      return []
    end

    if not reqs.first.kind_of? Array then
      reqs = [ reqs ]
    end

    reqs.each_with_index do |r, i|
      if r.kind_of? Request then
        @reqs << r
      elsif r.kind_of? Array then
        @reqs << Request.new(i, r.shift, :post, r.shift)
      end
    end

    return collate_results(perform())
  end

  # Execute requests. By default, will block until complete and return results.
  #
  # @param [Boolean] async      If true, will not wait for requests to finish.
  #                             (Default=false)
  #
  # @param [Block] block        If passed, responses will be passed into the callback
  #                             instead of being returned directly
  #
  # @yield [Request, String]    Passes to the block the request and the response body
  #
  # @return [Hash<Key, String>] Hash of responses, if no block given. Returns true otherwise
  def perform(async=false, &block)

    @results = {}

    @clients.each do |client|
      @threads << Thread.new do

        loop do
          break if @reqs.empty?
          req = @reqs.shift
          break if req.nil? # can sometimes reach here due to a race condition. saw it a lot on travis
          client.url = req.uri

          args = ["http_#{req.method}"]
          if [:put, :post].include? req.method
            # add body to args for these methods
            if req.body then
              if req.body.kind_of? Array then
                args += req.body
              else
                args << req.body
              end
            else
              args << ""
            end
          end

          client.send(*args)
          if block then
            yield(req, client.body_str)
          else
            @results[req.key] = client.body_str
          end
        end

      end
    end

    if async then
      # don't wait for threads to join, just return
      return true
    end

    join()
    return true if block

    return @results
  end


  private

  # Create ordered array from hash of results
  def collate_results(results)
    ret = []
    results.size.times do |i|
      ret << results[i]
    end
    return ret
  end

end # ThreadPool
end # Curl
