# frozen_string_literal: true

ENV['APP_ENV'] = 'test'
ENV['LINKS_FILE'] = 'test/links.json'
File.write('test/links.json', '{}')

require 'minitest/autorun'
require 'rack/test'

require_relative '../app/app'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_shorten_creates_link
    post '/shorten', url: 'https://ruby-lang.org'
    assert_equal 201, last_response.status
  end

  def test_invalid_url_returns400
    post '/shorten', url: 'banana'
    assert_equal 400, last_response.status
    assert_includes last_response.body, 'Invalid URL'
  end

  def test_same_url_returns_same_link
    post '/shorten', url: 'https://exemplo.com'
    assert_equal 201, last_response.status
    first_link = last_response.body[/href="([^"]+)"/, 1]

    post '/shorten', url: 'https://exemplo.com'
    assert_equal 200, last_response.status
    assert_includes last_response.body, first_link
  end
end
