require 'json'
require 'yaml'

module BenchmarkDriver
  class BenchmarkFile
    class << self
      def read(path)
        case File.extname(path)
        when /(yaml|yml)$/i
          YAML.load(File.read(path))
        when /json$/i
          JSON.parse(File.read(path))
        else
          raise "unknown file type"
        end
      end
    end
  end
end
