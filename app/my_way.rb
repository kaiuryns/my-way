# frozen_string_literal: true

module MyWay
  APP_ROOT = File.expand_path("..", __dir__)

  DATABASE_PATH = ENV.fetch("DATABASE_PATH", File.join(APP_ROOT, "db", "my_way.sqlite3"))

  LEGACY_LINKS_FILE = ENV.fetch("LINKS_FILE", File.join(APP_ROOT, "links.json"))

  class << self
    def boot!
      Connection.instance
      self
    end

    def repository
      @repository ||= LinkRepository.new(Connection.instance)
    end

    def shorten_link
      @shorten_link ||= ShortenLink.new(repository: repository)
    end
  end
end

require_relative "db/schema"
require_relative "db/connection"
require_relative "models/link"
require_relative "models/link_repository"
require_relative "services/shorten_link"