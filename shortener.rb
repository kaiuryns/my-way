# frozen_string_literal: true

require 'securerandom'
require 'uri'

def generate_code(codes)
  3.times do
    code = SecureRandom.alphanumeric(5)
    return code unless code?(code, codes)
  end
  raise 'Cant generate a code, try a custom one'
end

def code?(code, codes)
  codes.key? code
end

def valid_url?(url)
  uri = URI.parse(url.to_s)
  %w[http https].include?(uri.scheme) && uri.host
rescue URI::InvalidURIError
  false
end

def valid_code?(code)
  code.match?(/\A[A-Za-z0-9_-]{3,30}\z/)
end
