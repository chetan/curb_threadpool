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
    stub(:get)
    ret = @pool.get(@url)

    assert ret
    assert_equal 1, ret.size
    assert_equal "res 1", ret.first
  end

  def test_get_array_param
    stub(:get)
    ret = @pool.get([@url])

    assert ret
    assert_equal 1, ret.size
    assert_equal "res 1", ret.first
  end

  def test_get_multiple
    stub(:get)
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

  def test_post
    stub(:post)
    pool = Curl::ThreadPool.new
    ret = pool.post([@url, ""])

    assert ret
    assert_equal 1, ret.size
    assert_equal "res 1", ret.first
  end

  def test_post_multiple
    stub(:post)
    pool = Curl::ThreadPool.new
    reqs = [
      [@url, "foobar"],
      [@url, "blah"]
    ]
    ret = pool.post(reqs)

    assert ret
    assert_equal 2, ret.size
    assert_equal "res 1", ret.first
    assert_equal "res 2", ret.last
  end


  private

  def stub(method)
    stub = stub_request(method, "http://www.google.com/").
      to_return {
        @i += 1
        { :status => 200, :body => "res #{@i}" }
      }
  end

end
