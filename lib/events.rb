module Events # :nodoc:
  UncaughtError = Class.new(StandardError)
  
  # The Events::Emitter mixin provides a clone of the Node.js EventEmitter API
  # for Ruby.
  # 
  # Instances of classes including Events::Emitter will emit events, events are
  # represented by symbols, underscored in the usual Ruby fashion. Examples:
  # :connection, :data, :message_begin
  # 
  # Blocks can be attached to objects to be executed when an event is emitted,
  # these blocks are called listeners.
  # 
  # All EventEmitters emit the event :new_listener when new listeners are added,
  # this listener is provided with the event and new listener added.
  # Example:
  #   server.on(:new_listener) do |event, listener|
  #     puts "added new listener #{listener} for event #{event}"
  #   end
  #   
  #   server.on(:connection) do |socket|
  #     puts "someone connected!"
  #   end
  # Outputs "added new listener #<Proc:0x0000000000000000@example.rb:12> for
  # event connection".
  # 
  # When an EventEmitter experiences an error, the typical action is to emit an
  # :error event. Error events are special -- if there is no handler for them
  # they raise an Events::UncaughtError exception.
  # 
  module Emitter
    
    # :call-seq: emitter.listeners(event) -> array
    # 
    # Returns an array of listeners for the specified event. This array can be
    # manipulated, e.g. to remove listeners.
    # 
    def listeners(event)
      (@listeners ||= Hash.new {|hash, key| hash[key] = []})[event]
    end
    
    # :call-seq: emitter.emit(event[, arguments...]) -> bool
    # 
    # Execute each of the listeners in order with the supplied arguments.
    # 
    def emit(event, *args)
      listeners = listeners(event).dup
      
      if event == :error && listeners.empty?
        raise args.first if args.first.kind_of?(Exception)
        raise Events::UncaughtError.new("Uncaught, unspecified 'error' event.")
      end
      
      listeners.each do |listener|
        listener.call(*args)
      end.any?
    end
    
    # :call-seq: emitter.on(event) {|args...| block} -> emitter
    # emitter.on(event, proc) -> emitter
    # 
    # Adds a listener to the end of the listeners array for the specified event.
    #   server.on(:connection) do |socket|
    #     puts "someone connected!"
    #   end
    # 
    # Rather than a block, can take a second argument of a Proc (or any object
    # with a #call method).
    # 
    def add_listener(event, proc=nil, &block)
      emit(:new_listener, event, proc || block)
      listeners(event).push(proc || block)
      self
    end
    alias on add_listener
    
    
    # :call-seq: emitter.once(event) {|args...| block} -> emitter
    # emitter.once(event, proc) -> emitter
    # 
    # Adds a one time listener for the event. The listener is invoked only the
    # first time the event is fired, after which it is removed.
    #   server.once(:connection) do |socket|
    #     puts "Ah, we have our first user!"
    #   end
    # 
    def once(event, proc=nil, &block)
      once = Proc.new do |*args|
        remove_listener(event, once)
        (proc || block).call(args)
      end
      add_listener(event, once)
    end
    
    # :call-seq: emitter.remove_listener(event, proc) -> emitter
    # 
    # Remove a listener from the listener array for the specified event.
    # 
    def remove_listener(event, proc)
      if @listeners && @listeners.key?(event)
        @listeners[event].delete(proc)
        @listeners.delete(event) if @listeners[event].empty?
      end
      self
    end
    
    # :call-seq: emitter.remove_all_listeners(event) -> emitter
    # 
    # Removes all listeners from the listener array for the specified event.
    # 
    def remove_all_listeners(event)
      if @listeners && @listeners.key?(event)
        @listeners[event].clear
        @listeners.delete(event)
      end
      self
    end
  end
  
  # The Events::EventEmitter class provides a clone of the Node.js EventEmitter
  # API for Ruby.
  # 
  # It simply includes the Events::Emitter module, and is provided as a
  # convenience for those who wish to inherit from a class.
  # 
  # See Events::Emitter for more.
  # 
  class EventEmitter
    include Emitter
  end
end