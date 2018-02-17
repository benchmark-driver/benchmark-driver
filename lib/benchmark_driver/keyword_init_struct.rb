module BenchmarkDriver
  class << KeywordInitStruct = Module.new
    # @param [Array<Symbol>] args
    def new(*args, &block)
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5.0')
        klass = Struct.new(*args, keyword_init: true, &block)
      else
        klass = keyword_init_struct(*args, &block)
      end

      # Freeze members too
      klass.class_eval do
        def freeze
          members.each do |member|
            value = public_send(member)
            if value.is_a?(Array)
              value.each(&:freeze)
            end
            value.freeze
          end
          super
        end
      end

      klass
    end

    private

    # Polyfill for Ruby < 2.5.0
    def keyword_init_struct(*args, &block)
      Struct.new(*args).tap do |klass|
        klass.prepend(Module.new {
          # @param [Hash{ Symbol => Object }] args
          def initialize(**args)
            args.each do |key, value|
              unless members.include?(key)
                raise ArgumentError.new("unknwon keywords: #{key}")
                next
              end

              send("#{key}=", value)
            end
          end
        })
        klass.prepend(Module.new(&block))
      end
    end
  end
end
