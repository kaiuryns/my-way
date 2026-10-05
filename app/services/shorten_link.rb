# frozen_string_literal: true

module MyWay
  class ShortenLink
    Outcome = Data.define(:status, :link, :message) do
      def success?
        status == :created || status == :exists
      end
    end

    MESSAGES = {
      invalid_url: "Invalid URL",
      invalid_code: "Invalid code",
      code_taken: "Code already in use",
      exhausted: "Cant generate a code, try a custom one"
    }.freeze

    def initialize(repository:)
      @repository = repository
    end

    def call(url:, code: nil)
      url = url.to_s.strip
      code = code.to_s.strip

      return failure(:invalid_url) unless Link.valid_url?(url)

      existing = repository.find_by_url(url)
      if existing
        return outcome(:exists, link: existing) if code.empty? || code == existing.code

        return failure(:url_taken, message: "URL already has code #{existing.code}")
      end

      if code.empty?
        create_with_generated_code(url)
      else
        create_with_custom_code(url, code)
      end
    end

    private

    attr_reader :repository

    def create_with_custom_code(url, code)
      return failure(:invalid_code) unless Link.valid_code?(code)
      return failure(:code_taken) if repository.code_taken?(code)
      return failure(:code_taken) unless repository.insert(Link.new(code: code, url: url))

      outcome(:created, link: Link.new(code: code, url: url))
    end

    def create_with_generated_code(url)
      code = Link.generate_code(reject: ->(candidate) { repository.code_taken?(candidate) })
      return failure(:exhausted) if code.nil?

      link = Link.new(code: code, url: url)
      return outcome(:created, link: link) if repository.insert(link)

      # The URL was claimed by a concurrent request while we were working.
      winner = repository.find_by_url(url)
      return outcome(:exists, link: winner) if winner

      failure(:exhausted)
    end

    def outcome(status, link: nil)
      Outcome.new(status: status, link: link, message: nil)
    end

    def failure(status, message: nil)
      Outcome.new(status: status, link: nil, message: message || MESSAGES.fetch(status))
    end
  end
end