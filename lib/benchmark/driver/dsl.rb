require 'benchmark/driver/configuration'

class Benchmark::Driver::DSL
  def initialize
    @prelude = nil
    @reports = []
  end

  # API to fetch configuration parsed from DSL
  # @return [Benchmark::Driver::Configuration]
  def configuration
    Benchmark::Driver::Configuration.new(@prelude, @reports)
  end

  # @param [String] prelude - Script required for benchmark whose execution time is not measured.
  def prelude=(prelude)
    unless prelude.is_a?(String)
      raise ArgumentError.new("prelude must be String but got #{prelude.inspect}")
    end
    unless @prelude.nil?
      raise ArgumentError.new("prelude is already set:\n#{@prelude}")
    end

    @prelude = prelude
  end

  # @param [String,nil] name   - Name shown on result output. This must be provided if block is given.
  # @param [String,nil] script - Benchmarked script in String. Only either of script or block must be provided.
  # @param [Proc,nil]   block  - Benchmarked Proc object.
  def report(name = nil, script: nil, &block)
    if script.nil? && !block_given?
      raise ArgumentError.new('script or block must be provided')
    elsif !script.nil? && block_given?
      raise ArgumentError.new('script and block cannot be specified at the same time')
    elsif name.nil? && block_given?
      raise ArgumentError.new('name must be specified if block is given')
    elsif !name.nil? && !name.is_a?(String)
      raise ArgumentError.new("name must be String but got #{name.inspect}")
    elsif !script.nil? && script.is_a?(String)
      raise ArgumentError.new("script must be String but got #{script.inspect}")
    end

    @reports << Benchmark::Driver::Configuration::Report.new(name, script || block)
  end
end
