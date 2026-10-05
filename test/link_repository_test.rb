# frozen_string_literal: true

require_relative "test_helper"

class LinkRepositoryTest < MyWayTest
  def setup
    super
    @repository = MyWay.repository
  end

  def test_insert_then_find_by_code_and_by_url
    link = build(code: "abc12", url: "https://example.com")

    assert @repository.insert(link)
    assert_equal link, @repository.find_by_code("abc12")
    assert_equal link, @repository.find_by_url("https://example.com")
    assert_equal 1, @repository.count
  end

  def test_find_returns_nil_for_unknown_code_or_url
    assert_nil @repository.find_by_code("nope1")
    assert_nil @repository.find_by_url("https://nothing.com")
  end

  def test_code_taken_predicate
    @repository.insert(build(code: "abc12", url: "https://example.com"))

    assert @repository.code_taken?("abc12")
    refute @repository.code_taken?("zzz99")
  end

  def test_insert_rejects_a_duplicate_code
    @repository.insert(build(code: "abc12", url: "https://example.com"))

    refute @repository.insert(build(code: "abc12", url: "https://other.com"))
    assert_equal 1, @repository.count
  end

  def test_insert_rejects_a_duplicate_url
    @repository.insert(build(code: "abc12", url: "https://example.com"))

    refute @repository.insert(build(code: "zzz99", url: "https://example.com"))
    assert_equal 1, @repository.count
  end

  private

  def build(code:, url:)
    MyWay::Link.new(code: code, url: url)
  end
end