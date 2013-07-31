require 'helper'

class TestCurbThreadpool < MiniTest::Unit::TestCase

  def setup
    super
    WebMock.reset!
    @url = "http://www.google.com"
    @pool = Curl::ThreadPool.new
    @i = 0
  end

  def teardown
    super
    @pool.reset()
  end

  def test_get
    stub_get()
    ret = @pool.get(@url)

    assert ret
    assert_equal 1, ret.size
    assert_equal "res 1", ret.first
  end

  def test_get_array_param
    stub_get()
    ret = @pool.get([@url])

    assert ret
    assert_equal 1, ret.size
    assert_equal "res 1", ret.first
  end

  def test_get_multiple
    stub_get()
    urls = [@url, @url, @url]
    ret = @pool.get(urls)
    assert ret
    assert_equal 3, ret.size
    ret.each_with_index do |r, idx|
      assert_equal "res #{idx+1}", r
    end
  end

  def test_get_nil
    pool = Curl::ThreadPool.new
    ret = pool.get([])
    assert_kind_of Array, ret
    assert_empty ret
  end


  private

  def stub_get
    stub = stub_request(:get, "http://www.google.com/").
      to_return {
        @i += 1
        { :status => 200, :body => "res #{@i}" }
      }
  end



end
