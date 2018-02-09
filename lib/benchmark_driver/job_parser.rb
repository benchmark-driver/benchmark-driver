module BenchmarkDriver::JobParser
  class << self
    # @param [Object] config
    def symbolize_keys!(config)
      case config
      when Hash
        config.keys.each do |key|
          config[key.to_sym] = symbolize_keys!(config.delete(key))
        end
      when Array
        config.map! { |c| symbolize_keys!(c) }
      end
      config
    end

    def parse(config)
    end
  end
end
