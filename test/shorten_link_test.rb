# frozen_string_literal: true

require_relative "test_helper"

class ShortenLinkTest < MyWayTest
  def setup
    super
    @service = MyWay.shorten_link
  end

  def test_creates_a_link_with_a_generated_code
    outcome = @service.call(url: "https://example.com")

    assert_equal :created, outcome.status
    assert outcome.success?
    assert_nil outcome.message
    assert_equal "https://example.com", outcome.link.url
    assert_equal MyWay::Link::CODE_LENGTH, outcome.link.code.length
  end

  def test_rejects_an_invalid_url_before_anything_else
    outcome = @service.call(url: "banana", code: "abc12")

    assert_equal :invalid_url, outcome.status
    assert_equal "Invalid URL", outcome.message
    assert_nil outcome.link
    assert_equal 0, MyWay.repository.count
  end

  def test_strips_surrounding_whitespace
    outcome = @service.call(url: "  https://example.com  ", code: "  abc12  ")

    assert_equal :created, outcome.status
    assert_equal "https://example.com", outcome.link.url
    assert_equal "abc12", outcome.link.code
  end

  def test_repeated_url_returns_the_same_code
    first = @service.call(url: "https://example.com")
    second = @service.call(url: "https://example.com")

    assert_equal :created, first.status
    assert_equal :exists, second.status
    assert_equal first.link.code, second.link.code
    assert_equal 1, MyWay.repository.count
  end

  def test_url_with_its_own_custom_code_returns_exists
    @service.call(url: "https://example.com", code: "abc12")
    outcome = @service.call(url: "https://example.com", code: "abc12")

    assert_equal :exists, outcome.status
    assert_equal "abc12", outcome.link.code
  end

  def test_url_already_shortened_with_a_different_code_is_a_conflict
    @service.call(url: "https://example.com", code: "abc12")
    outcome = @service.call(url: "https://example.com", code: "zzz99")

    assert_equal :url_taken, outcome.status
    assert_equal "URL already has code abc12", outcome.message
    refute outcome.success?
  end

  def test_rejects_an_invalid_custom_code
    outcome = @service.call(url: "https://example.com", code: "no")

    assert_equal :invalid_code, outcome.status
    assert_equal "Invalid code", outcome.message
    assert_equal 0, MyWay.repository.count
  end

  def test_rejects_a_custom_code_already_in_use
    @service.call(url: "https://example.com", code: "abc12")
    outcome = @service.call(url: "https://other.com", code: "abc12")

    assert_equal :code_taken, outcome.status
    assert_equal "Code already in use", outcome.message
    assert_equal 1, MyWay.repository.count
  end

  def test_generated_code_avoids_taken_codes
    taken = MyWay::Link.generate_code(reject: ->(_candidate) { false })
    MyWay.repository.insert(MyWay::Link.new(code: taken, url: "https://other.com"))

    outcome = @service.call(url: "https://example.com")

    assert_equal :created, outcome.status
    refute_equal taken, outcome.link.code
  end

  def test_reports_unavailable_when_no_code_can_be_generated
    service = MyWay::ShortenLink.new(repository: always_taken_repository)

    outcome = service.call(url: "https://example.com")

    assert_equal :exhausted, outcome.status
    assert_equal "Cant generate a code, try a custom one", outcome.message
  end

  private

  def always_taken_repository
    MyWay::LinkRepository.new(MyWay::Connection.instance).tap do |repository|
      def repository.code_taken?(_code) = true
    end
  end
end