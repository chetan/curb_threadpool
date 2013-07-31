
require "curb"

# A multi-threaded worker pool for Curb
module Curl
class ThreadPool

  attr_reader :results

  def initialize(size=4)
    @size = size
    reset()
  end

  # Add a URL to be fetched
  #
  # @param [Object] key  to use for request
  # @param [String] url  URL to fetch
  def []=(key, url)
    @reqs[key] = url
  end
  alias :add :[]=

  # Wait for all threads to complete
  def join
    @threads.each { |t| t.join }
    @threads.clear
  end

  # Close all active Curl connections
  def close
    @clients.each { |c| c.reset(); c.close() } if @clients
  end

  # Reset the ThreadPool
  def reset
    close()
    @reqs = {}
    @results = {}
    @clients = []
    @threads = []
    @size.times{ @clients << Curl::Easy.new }
  end

  # Utility method for retrieving a list of URLs
  #
  # @param [Array<String>] urls   list of URLs
  # @return [Array] array of response bodies
  def get(urls)
    if urls.nil? or urls.empty? then
      return []
    end

    urls = [urls] if not urls.kind_of? Array
    urls.each_with_index do |url, i|
      @reqs[i] = url.to_s
    end

    results = perform()

    ret = []
    (0..results.size-1).each do |i|
      ret << results[i]
    end

    return ret
  end

  # Execute requests. By default, will block until complete and return results.
  #
  # @param [Boolean] no_block   If true, will not wait for requests to finish.
  #                             (Default=false)
  #
  # @param [Block] block        If passed, responses will be passed into the callback
  #                             instead of being returned directly
  #
  # @return [Hash<Key, String>] Hash of responses, if no block given
  def perform(no_block=false, &block)

    @results = {} if not @results.empty?

    @clients.each do |client|
      @threads << Thread.new do

        loop do
          break if @reqs.empty?
          (key, url) = @reqs.shift
          client.url = url
          client.http_get
          if block then
            yield(key, client.body_str)
          else
            @results[key] = client.body_str
          end
        end

      end
    end

    return {} if no_block

    join()
    return true if block

    ret = @results
    @results = {}
    return ret
  end

end # ThreadPool
end # Curl
