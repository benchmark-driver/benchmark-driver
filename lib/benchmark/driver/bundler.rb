# This module can be transparently run even if Bundler is not installed
module Benchmark::Driver::Bundler
  def self.with_clean_env(&block)
    begin
      require 'bundler'
    rescue LoadError
      block.call # probably bundler is not used
    else
      ::Bundler.with_clean_env { block.call }
    end
  end
end
