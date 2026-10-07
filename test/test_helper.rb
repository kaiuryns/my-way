# frozen_string_literal: true

ENV['APP_ENV'] = 'test'

require 'fileutils'
require 'minitest/autorun'
require 'rack/test'
require 'tmpdir'

TEST_ROOT = Dir.mktmpdir('my-way-test')
ENV['DATABASE_PATH'] = File.join(TEST_ROOT, 'test.sqlite3')

require_relative '../app/controllers/application'

at_exit { FileUtils.remove_entry(TEST_ROOT, true) }

module CleanDatabase
  def setup
    super
    MyWay.boot!
    MyWay::Connection.instance.execute('DELETE FROM links')
  end
end

module RackApp
  include Rack::Test::Methods

  def app
    MyWay::Application
  end
end

class MyWayTest < Minitest::Test
  include CleanDatabase
end
