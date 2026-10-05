# frozen_string_literal: true

require_relative "test_helper"

class ApplicationTest < MyWayTest
  include RackApp

  def test_home_page_renders_the_form
    get "/"

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'action="/shorten"'
    assert_includes last_response.body, 'name="url"'
    assert_includes last_response.body, 'name="code"'
  end

  def test_shorten_creates_a_link
    post "/shorten", url: "https://ruby-lang.org"

    assert_equal 201, last_response.status
    link = MyWay.repository.find_by_url("https://ruby-lang.org")
    assert_equal "https://ruby-lang.org", link.url
    assert_equal MyWay::Link::CODE_LENGTH, link.code.length
  end

  def test_shorten_returns_a_clickable_short_link
    post "/shorten", url: "https://ruby-lang.org"
    short_link = last_response.body[/href="([^"]+)"/, 1]

    assert_equal 201, last_response.status
    assert short_link.start_with?("http://example.org/")
    assert_includes last_response.body, "Short link:"
  end

  def test_shorten_honours_a_custom_code
    post "/shorten", url: "https://ruby-lang.org", code: "my-docs"

    assert_equal 201, last_response.status
    assert_equal "my-docs", MyWay.repository.find_by_url("https://ruby-lang.org").code
    assert_includes last_response.body, "http://example.org/my-docs"
  end

  def test_invalid_url_returns_400
    post "/shorten", url: "banana"

    assert_equal 400, last_response.status
    assert_includes last_response.body, "Invalid URL"
  end

  def test_invalid_custom_code_returns_400
    post "/shorten", url: "https://ruby-lang.org", code: "no"

    assert_equal 400, last_response.status
    assert_includes last_response.body, "Invalid code"
  end

  def test_same_url_returns_the_same_link
    post "/shorten", url: "https://exemplo.com"
    first_link = last_response.body[/href="([^"]+)"/, 1]

    post "/shorten", url: "https://exemplo.com"

    assert_equal 200, last_response.status
    assert_includes last_response.body, first_link
  end

  def test_taken_custom_code_returns_409
    post "/shorten", url: "https://a.example", code: "shared"
    post "/shorten", url: "https://b.example", code: "shared"

    assert_equal 409, last_response.status
    assert_includes last_response.body, "Code already in use"
  end

  def test_conflicting_custom_code_for_same_url_returns_409
    post "/shorten", url: "https://a.example", code: "first"
    post "/shorten", url: "https://a.example", code: "second"

    assert_equal 409, last_response.status
    assert_includes last_response.body, "URL already has code first"
  end

  def test_code_redirects_to_the_original_url
    post "/shorten", url: "https://ruby-lang.org", code: "ruby"
    get "/ruby"

    assert_equal 302, last_response.status
    assert_equal "https://ruby-lang.org", last_response.headers["location"]
  end

  def test_unknown_code_returns_404
    get "/nothing-here"

    assert_equal 404, last_response.status
    assert_includes last_response.body, "That short link does not exist."
  end

  def test_json_shorten_returns_the_link
    post "/shorten", { url: "https://ruby-lang.org", code: "ruby" },
         { "HTTP_ACCEPT" => "application/json" }

    assert_equal 201, last_response.status
    assert_includes last_response.content_type, "application/json"
    assert_equal(
      { "code" => "ruby", "url" => "https://ruby-lang.org", "short_url" => "http://example.org/ruby" },
      JSON.parse(last_response.body)
    )
  end

  def test_json_shorten_via_query_param
    post "/shorten?format=json", url: "https://ruby-lang.org", code: "ruby"

    assert_equal 201, last_response.status
    assert_equal "ruby", JSON.parse(last_response.body).fetch("code")
  end

  def test_json_error_returns_400
    post "/shorten", { url: "banana" }, { "HTTP_ACCEPT" => "application/json" }

    assert_equal 400, last_response.status
    assert_includes last_response.content_type, "application/json"
    assert_equal({ "error" => "Invalid URL" }, JSON.parse(last_response.body))
  end

  def test_json_unknown_code_returns_404
    get "/nothing-here", {}, { "HTTP_ACCEPT" => "application/json" }

    assert_equal 404, last_response.status
    assert_includes last_response.content_type, "application/json"
    assert_equal({ "error" => "Link not found" }, JSON.parse(last_response.body))
  end

  def test_browser_accept_header_gets_html
    get "/", {}, { "HTTP_ACCEPT" => "text/html,application/xhtml+xml" }

    assert_includes last_response.content_type, "text/html"
  end
end