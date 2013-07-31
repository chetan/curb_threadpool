require 'helper'

class TestCurbThreadpool < MiniTest::Unit::TestCase

  def setup
    WebMock.reset!
  end

  def test_get
    i = 0
    stub = stub_request(:get, "http://www.google.com/").
      to_return {
        i += 1
        { :status => 200, :body => "res #{i}" }
      }

    url = "http://www.google.com"
    pool = Curl::ThreadPool.new
    ret = pool.get(url)

    assert ret
    assert_equal 1, ret.size
    assert_equal "res 1", ret.first

    ret = pool.get([url])

    assert ret
    assert_equal 1, ret.size
    assert_equal "res 2", ret.first

    i = 0
    urls = [url, url, url]
    ret = pool.get(urls)
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
  end

end
