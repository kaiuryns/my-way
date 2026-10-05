# frozen_string_literal: true

require "json"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "."
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = true
end

desc "Run the app via config.ru"
task :run do
  sh "bundle exec rackup"
end

namespace :db do
  desc "Import the legacy links.json file (url => code) into SQLite"
  task :import do
    require_relative "app/my_way"

    MyWay.boot!
    path = MyWay::LEGACY_LINKS_FILE

    unless File.exist?(path)
      puts "#{path} not found, nothing to import."
      next
    end

    legacy = JSON.parse(File.read(path))
    imported = legacy.count do |url, code|
      next false unless MyWay::Link.valid_url?(url) && MyWay::Link.valid_code?(code)

      MyWay.repository.insert(MyWay::Link.new(code: code, url: url))
    end

    puts "Imported #{imported} of #{legacy.size} links into #{MyWay::DATABASE_PATH}."
  end
end

task default: :test