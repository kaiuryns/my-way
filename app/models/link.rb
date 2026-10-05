# frozen_string_literal: true

require "securerandom"
require "uri"

module MyWay
  Link = Data.define(:code, :url)

  class Link
    CODE_FORMAT = /\A[A-Za-z0-9_-]{3,30}\z/
    CODE_LENGTH = 5
    CODE_GENERATION_ATTEMPTS = 3

    class << self
      def valid_url?(url)
        uri = URI.parse(url.to_s)
        %w[http https].include?(uri.scheme) && !uri.host.nil? && !uri.host.empty?
      rescue URI::InvalidURIError
        false
      end

      def valid_code?(code)
        CODE_FORMAT.match?(code.to_s)
      end

      def generate_code(reject:)
        CODE_GENERATION_ATTEMPTS.times do
          code = SecureRandom.alphanumeric(CODE_LENGTH)
          return code unless reject.call(code)
        end

        nil
      end
    end

    def to_h
      { code: code, url: url }
    end
  end
end