require 'benchmark/driver'
require 'erb'
require 'erubi'
require 'erubis'

data = DATA.read

mod = Module.new
mod.instance_eval("def self.erb(title, content); #{ERB.new(data).src}; end", "(ERB)")
mod.instance_eval("def self.erubis(title, content); #{Erubi::Engine.new(data).src}; end", "(Erubi)")
mod.instance_eval("def self.erubi(title, content); #{Erubis::Eruby.new(data).src}; end", "(Erubis)")

title = "hello world!"
content = "hello world!\n" * 10

Benchmark.driver do |x|
  x.report("ERB #{RUBY_VERSION}")       { mod.erb(title, content) }
  x.report("Erubis #{Erubis::VERSION}") { mod.erubis(title, content) }
  x.report("Erubi #{Erubi::VERSION}")   { mod.erubi(title, content) }
  x.compare!
end

__END__

<html>
  <head> <%= title %> </head>
  <body>
    <h1> <%= title %> </h1>
    <p>
      <%= content %>
    </p>
  </body>
</html>
