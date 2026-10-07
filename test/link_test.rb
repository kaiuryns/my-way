# frozen_string_literal: true

require_relative 'test_helper'

class LinkTest < Minitest::Test
  def test_valid_url_accepts_http_and_https
    assert MyWay::Link.valid_url?('http://ruby-lang.org')
    assert MyWay::Link.valid_url?('https://ruby-lang.org')
    assert MyWay::Link.valid_url?('https://ruby-lang.org/docs?q=1#top')
  end

  def test_valid_url_rejects_other_schemes_and_junk
    refute MyWay::Link.valid_url?('ftp://ruby-lang.org')
    refute MyWay::Link.valid_url?('javascript:alert(1)')
    refute MyWay::Link.valid_url?('banana')
    refute MyWay::Link.valid_url?('https://')
    refute MyWay::Link.valid_url?(nil)
    refute MyWay::Link.valid_url?('')
    refute MyWay::Link.valid_url?('http://exa mple.com')
  end

  def test_valid_code_bounds
    assert MyWay::Link.valid_code?('abc')
    assert MyWay::Link.valid_code?('a-b_C9')
    assert MyWay::Link.valid_code?('a' * 30)

    refute MyWay::Link.valid_code?('ab')
    refute MyWay::Link.valid_code?('a' * 31)
    refute MyWay::Link.valid_code?('has space')
    refute MyWay::Link.valid_code?('slash/es')
    refute MyWay::Link.valid_code?('dot.dot')
    refute MyWay::Link.valid_code?(nil)
  end

  def test_generate_code_returns_free_code_of_expected_length
    code = MyWay::Link.generate_code(reject: ->(_candidate) { false })

    assert_equal MyWay::Link::CODE_LENGTH, code.length
    assert MyWay::Link.valid_code?(code)
  end

  def test_generate_code_skips_taken_codes
    taken = MyWay::Link.generate_code(reject: ->(_candidate) { false })

    code = MyWay::Link.generate_code(reject: ->(candidate) { candidate == taken })

    refute_nil code
    refute_equal taken, code
  end

  def test_generate_code_gives_up_after_the_configured_attempts
    attempts = 0
    code = MyWay::Link.generate_code(reject: lambda { |_candidate|
      attempts += 1
      true
    })

    assert_nil code
    assert_equal MyWay::Link::CODE_GENERATION_ATTEMPTS, attempts
  end

  def test_to_h
    link = MyWay::Link.new(code: 'abc12', url: 'https://example.com')

    assert_equal({ code: 'abc12', url: 'https://example.com' }, link.to_h)
  end
end
