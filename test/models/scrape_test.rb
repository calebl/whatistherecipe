require "test_helper"

class ScrapeTest < ActiveSupport::TestCase
  test "should not save scrape without hostname" do
    scrape = Scrape.new(request_uri: "/test")
    assert_not scrape.save, "Saved the scrape without a hostname"
  end

  test "should not save scrape without request_uri" do
    scrape = Scrape.new(hostname: "example.com")
    assert_not scrape.save, "Saved the scrape without a request_uri"
  end

  test "should not save duplicate scrape with same hostname and request_uri" do
    Scrape.create(hostname: "example.com", request_uri: "/test")
    scrape2 = Scrape.new(hostname: "example.com", request_uri: "/test")
    assert_not scrape2.save, "Saved duplicate scrape with same hostname and request_uri"
  end

  test "should save scrape with same hostname but different request_uri" do
    Scrape.create(hostname: "example.com", request_uri: "/test1")
    scrape2 = Scrape.new(hostname: "example.com", request_uri: "/test2")
    assert scrape2.save, "Could not save scrape with same hostname but different request_uri"
  end

  test "should save scrape with same request_uri but different hostname" do
    Scrape.create(hostname: "example1.com", request_uri: "/test")
    scrape2 = Scrape.new(hostname: "example2.com", request_uri: "/test")
    assert scrape2.save, "Could not save scrape with same request_uri but different hostname"
  end
end
