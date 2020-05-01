module BenchmarkDriver
  class RubyTopLevelDSL
    module DSL
      private

      def prelude(script)
        INSTANCE.prelude(script)
      end

      def report(name, script = name)
        INSTANCE.report(name, script)
      end
    end

    def self.load(path)
      MAIN_OBJECT.extend(DSL)
      Kernel.load path
      INSTANCE.build_config
    end

    def initialize
      @prelude = ''
      @jobs = {}
    end

    def build_config
      {
        prelude: @prelude,
        benchmark: @jobs
      }
    end

    # @param [String] script
    def prelude(script)
      @prelude << "#{script}\n"
    end

    # @param [String] name - Name shown on result output.
    # @param [String,nil] script - Benchmarked script in String. If nil, name is considered as script too.
    def report(name, script = name)
      # @jobs << { benchmark: [{ name: name, script: script }] }
      @jobs[name] = script
    end

    INSTANCE = new
  end
end

BenchmarkDriver::RubyTopLevelDSL::MAIN_OBJECT = self
