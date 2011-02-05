Gem::Specification.new do |s|
  s.name = "events"
  s.version = "0.9.4"
  s.summary = "Clone of the node.js EventEmitter api for Ruby"
  s.description = "The Events::Emitter mixin provides a clone of the Node.js EventEmitter API for Ruby."
  s.files = Dir["lib/**/*.rb"] + Dir["test/*.*"]
  s.test_files = ["test/event_emitter_test.rb"]
  s.require_path = "lib"
  s.has_rdoc = true
  s.extra_rdoc_files = ["readme.rdoc"]
  s.rdoc_options << "--main" << "readme.rdoc"
  s.author = "Matthew Sadler"
  s.email = "mat@sourcetagsandcodes.com"
  s.homepage = "http://github.com/matsadler/rb-event-emitter"
end