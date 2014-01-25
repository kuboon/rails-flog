# coding: utf-8
module Flog
  class Configuration
    attr_writer :ignore_cached_query

    def initialize
      @ignore_cached_query = true
    end

    def ignore_cached_query?
      !!@ignore_cached_query
    end
  end

  def self.config
    @@config ||= Flog::Configuration.new
  end

  def self.configure
    yield(config) if block_given?
  end
end