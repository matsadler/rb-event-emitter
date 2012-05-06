module Events # :nodoc:
  UncaughtError = Class.new(RuntimeError)
  
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
    DEFAULT_MAX_LISTENERS = 10
    
    class Listeners < Array
      attr_accessor :warned
    end
    
    class OnceWrapper < Proc
      attr_accessor :original
    end
    
    def max_listeners
      (defined?(@max_listeners) ? @max_listeners : DEFAULT_MAX_LISTENERS) || 0
    end
    private :max_listeners
    
    # :call-seq: emitter.max_listeners = integer -> integer
    #
    # By default an EventEmitter will print a warning if more than 10 listeners
    # are added to it. This is a useful default which helps finding memory
    # leaks. Obviously not all Emitters should be limited to 10. This method
    # allows that to be increased. Set to zero for unlimited.
    # 
    def max_listeners=(value)
      @max_listeners = value
    end
    alias set_max_listeners max_listeners=
    
    # :call-seq: emitter.listeners(event) -> array
    # 
    # Returns an array of listeners for the specified event. This array can be
    # manipulated, e.g. to remove listeners.
    # 
    def listeners(event)
      (@listeners ||= Hash.new {|hash, key| hash[key] = Listeners.new})[event]
    end
    
    # :call-seq: emitter.emit(event[, arguments...]) -> bool
    # 
    # Execute each of the listeners in order with the supplied arguments.
    # 
    def emit(event, *args)
      listeners = @listeners && @listeners.key?(event) && @listeners[event]
      
      if event == :error && (!listeners || listeners.empty?)
        raise *args if args.first.respond_to?(:exception)
        raise Events::UncaughtError, args.first if args.first.is_a?(String)
        raise Events::UncaughtError.new("Uncaught, unspecified 'error' event.")
      elsif listeners
        listeners.dup.each do |listener|
          listener.call(*args)
        end.any?
      else
        false
      end
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
      listener = proc || block
      unless listener.respond_to?(:call)
        raise ArgumentError.new("Listener must respond to #call")
      end
      
      to_emit = OnceWrapper === listener ? listener.original : listener
      emit(:new_listener, event, to_emit)
      
      event_listeners = listeners(event)
      event_listeners.push(listener)
      
      current = event_listeners.length
      if max_listeners > 0 && current > max_listeners && !event_listeners.warned
        warn(caller[1] +
          ": warning: possible EventEmitter memory leak detected. " <<
          "#{current} listeners added. " <<
          "Use Emitter#max_listeners = n to increase limit.")
        event_listeners.warned = true
      end
      
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
      listener = proc || block
      unless listener.respond_to?(:call)
        raise ArgumentError.new("Listener must respond to #call")
      end
      once = OnceWrapper.new do |*args|
        remove_listener(event, once)
        listener.call(*args)
      end
      once.original = listener
      
      add_listener(event, once)
    end
    
    # :call-seq: emitter.remove_listener(event, proc) -> emitter
    # 
    # Remove a listener from the listener array for the specified event.
    # 
    def remove_listener(event, proc)
      if @listeners && @listeners.key?(event)
        @listeners[event].delete_if do |lis|
          lis == proc || lis.respond_to?(:original) && lis.original == proc
        end
      end
      self
    end
    
    # :call-seq: emitter.remove_all_listeners -> emitter
    # emitter.remove_all_listeners(event) -> emitter
    # 
    # Removes all listeners, or those of the specified event.
    # 
    def remove_all_listeners(event=:_remove_all_listeners_default_arg_)
      @listeners = nil if event == :_remove_all_listeners_default_arg_
      if @listeners && @listeners.key?(event)
        @listeners[event].clear
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