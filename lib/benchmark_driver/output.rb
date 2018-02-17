require 'benchmark_driver/output/default'

module BenchmarkDriver
  class << Output
    # BenchmarkDriver::Output is pluggable.
    # Create `BenchmarkDriver::Output::Foo` as benchmark_dirver-output-foo.gem and specify `-o foo`.
    #
    # @param [String] type
    def find(type)
      if type.include?(':')
        raise ArgumentError.new("Output type '#{type}' cannot contain ':'")
      end

      ::BenchmarkDriver::Output.const_get(camelize(type), false)
    end

    private

    def camelize(str)
      str.split('_').map(&:capitalize).join
    end
  end
end
