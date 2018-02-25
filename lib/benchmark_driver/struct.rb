# Extended Struct with:
#   * Polyfilled `keyword_init: true`
#   * Default value configuration
#   * Deeply freezing members
module BenchmarkDriver
  class << Struct = Module.new
    # @param [Array<Symbol>] args
    # @param [Hash{ Symbol => Object }] defaults
    def new(*args, defaults: {}, &block)
      # Polyfill `keyword_init: true`
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5.0')
        klass = ::Struct.new(*args, keyword_init: true, &block)
      else
        klass = keyword_init_struct(*args, &block)
      end

      # Default value config
      configure_defaults(klass, defaults)

      # Force deeply freezing members
      force_deep_freeze(klass)

      klass
    end

    private

    # Polyfill for Ruby < 2.5.0
    def keyword_init_struct(*args, &block)
      ::Struct.new(*args).tap do |klass|
        klass.prepend(Module.new {
          # @param [Hash{ Symbol => Object }] args
          def initialize(**args)
            args.each do |key, value|
              unless members.include?(key)
                raise ArgumentError.new("unknwon keywords: #{key}")
                next
              end

              public_send("#{key}=", value)
            end
          end
        })
        klass.prepend(Module.new(&block))
      end
    end

    def configure_defaults(klass, defaults)
      class << klass
        attr_accessor :defaults
      end
      klass.defaults = defaults

      klass.prepend(Module.new {
        def initialize(**)
          super
          self.class.defaults.each do |key, value|
            if public_send(key).nil?
              begin
                value = value.dup
              rescue TypeError # for Ruby <= 2.3, like `true.dup`
              end
              public_send("#{key}=", value)
            end
          end
        end
      })

      def klass.inherited(child)
        child.defaults = self.defaults
      end
    end

    def force_deep_freeze(klass)
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
    end
  end
end
