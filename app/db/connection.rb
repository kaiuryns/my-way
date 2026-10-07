# frozen_string_literal: true

require 'fileutils'
require 'sqlite3'

module MyWay
  #  Shared SQLite connection.
  #
  # Opens the database on the first call to `instance` and reuses the same
  # connection afterwards. On open, it creates the directory if needed,
  # configures SQLite for concurrent access (WAL mode and a lock wait
  # timeout), and runs the Schema migrations.
  module Connection
    BUSY_TIMEOUT_MS = 5_000

    class << self
      def instance
        @instance ||= connect(DATABASE_PATH)
      end

      private

      def connect(path)
        FileUtils.mkdir_p(File.dirname(path)) if path != ':memory:'

        database = SQLite3::Database.new(path)
        database.results_as_hash = true
        configure_pragmas(database, path)
        Schema.migrate!(database)
      end

      def configure_pragmas(database, path)
        database.execute('PRAGMA journal_mode = WAL') unless path == ':memory:'
        database.execute('PRAGMA synchronous = NORMAL')

        if database.respond_to?(:busy_handler_timeout=)
          database.busy_handler_timeout = BUSY_TIMEOUT_MS
        else
          database.busy_timeout = BUSY_TIMEOUT_MS
        end
      end
    end
  end
end
