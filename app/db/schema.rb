# frozen_string_literal: true

module MyWay
  # Database schema for the URL shortener.
  #
  # Holds the SQL statements that create the `links` table and its index.
  # `migrate!` applies them idempotently (IF NOT EXISTS), so it is safe to
  # run on every connection.
  module Schema
    STATEMENTS = [
      <<~SQL,
        CREATE TABLE IF NOT EXISTS links (
          id         INTEGER PRIMARY KEY,
          code       TEXT    NOT NULL UNIQUE,
          url        TEXT    NOT NULL UNIQUE,
          created_at TEXT    NOT NULL DEFAULT (datetime('now'))
        )
      SQL
      'CREATE INDEX IF NOT EXISTS idx_links_url ON links (url)'
    ].freeze

    def self.migrate!(database)
      STATEMENTS.each { |statement| database.execute(statement) }
      database
    end
  end
end
