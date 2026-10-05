# frozen_string_literal: true

module MyWay
  class LinkRepository
    SELECT_COLUMNS = "code, url"

    def initialize(database)
      @database = database
    end

    def find_by_code(code)
      row_to_link(query_one("SELECT #{SELECT_COLUMNS} FROM links WHERE code = ?", code))
    end

    def find_by_url(url)
      row_to_link(query_one("SELECT #{SELECT_COLUMNS} FROM links WHERE url = ?", url))
    end

    def code_taken?(code)
      !find_by_code(code).nil?
    end

    def insert(link)
      database.prepare("INSERT INTO links (code, url) VALUES (?, ?)") do |statement|
        statement.execute(link.code, link.url)
      end

      true
    rescue SQLite3::ConstraintException
      false
    end

    def count
      database.get_first_value("SELECT COUNT(*) FROM links")
    end

    private

    attr_reader :database

    def query_one(sql, *binds)
      database.prepare(sql) do |statement|
        statement.execute(*binds).first
      end
    end

    def row_to_link(row)
      return nil if row.nil?

      Link.new(code: row["code"], url: row["url"])
    end
  end
end