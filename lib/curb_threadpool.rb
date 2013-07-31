
require "curb"

# A multi-threaded worker pool for Curb
module Curl
class ThreadPool

  attr_reader :reqs, :results

  # @!attribute [r] reqs
  #   @return [Hash] request key to URL hash

  def initialize(size=4)
    @size = size
    reset()
  end

  # Add a URL to be fetched
  #
  # @param [Object] key     to use for request
  # @param [String] url     URL to fetch
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
    if @clients then
      @clients.each { |c| c.reset(); c.close() }
    end
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
  #
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
  # @param [Boolean] async      If true, will not wait for requests to finish.
  #                             (Default=false)
  #
  # @param [Block] block        If passed, responses will be passed into the callback
  #                             instead of being returned directly
  #
  # @return [Hash<Key, String>] Hash of responses, if no block given. Returns true otherwise
  def perform(async=false, &block)

    @results = {}

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

    if async then
      # don't wait for threads to join, just return
      return true
    end

    join()
    return true if block

    return @results
  end

end # ThreadPool
end # Curl
