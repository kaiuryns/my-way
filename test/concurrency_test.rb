# frozen_string_literal: true

require_relative 'test_helper'

class ConcurrencyTest < MyWayTest
  THREADS = 10
  OPS_PER_THREAD = 5

  def test_concurrent_shortening_of_one_url_creates_exactly_one_link
    outcomes = in_parallel { MyWay.shorten_link.call(url: 'https://race.example') }

    assert_equal THREADS * OPS_PER_THREAD, outcomes.size
    assert_equal(1, outcomes.count { |outcome| outcome.status == :created })
    assert(outcomes.all? { |outcome| %i[exists created].include?(outcome.status) })

    codes = outcomes.map { |outcome| outcome.link.code }.uniq
    assert_equal 1, codes.size
    assert_equal 1, MyWay.repository.count
  end

  def test_concurrent_requests_for_one_custom_code_produce_one_winner
    outcomes = in_parallel do |index|
      MyWay.shorten_link.call(url: "https://contest-#{index}.example", code: 'contested')
    end

    assert_equal(1, outcomes.count { |outcome| outcome.status == :created })
    assert(
      outcomes.all? { |outcome| %i[created code_taken].include?(outcome.status) },
      "unexpected statuses: #{outcomes.map(&:status).uniq.inspect}"
    )

    assert_equal 1, MyWay.repository.count
    assert_equal 'contested', MyWay.repository.find_by_code('contested').code
  end

  private

  def in_parallel
    errors = Queue.new
    results = Queue.new

    threads = THREADS.times.flat_map do |thread|
      OPS_PER_THREAD.times.map do |op|
        Thread.new do
          results << yield((thread * OPS_PER_THREAD) + op)
        rescue StandardError => e
          errors << e
        end
      end
    end

    threads.each(&:join)

    raise errors.pop unless errors.empty?

    Array.new(results.size) { results.pop }
  end
end
