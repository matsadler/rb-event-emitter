module Events # :nodoc:
  
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
  #   server.add_listener(:new_listener) do |event, listener|
  #     puts "added new listener #{listener} for event #{event}"
  #   end
  #   
  #   server.add_listener(:connection) do |socket|
  #     puts "someone connected!"
  #   end
  # Outputs "added new listener #<Proc:0x0000000000000000@example.rb:12> for
  # event connection".
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
      
      listeners.each do |listener|
        listener.call(*args)
      end.any?
    end
    
    # :call-seq: emitter.add_listener(event, &block) -> emitter
    # 
    # Adds a listener to the end of the listeners array for the specified event.
    #   server.add_listener(:connection) do |socket|
    #     puts "someone connected!"
    #   end
    # 
    def add_listener(event, &block)
      emit(:new_listener, event, block)
      listeners(event).push(block)
      self
    end
    
    # :call-seq: emitter.remove_listener(event, proc) -> emitter
    # 
    # Remove a listener from the listener array for the specified event.
    # 
    def remove_listener(event, proc)
      listeners(event).delete(proc)
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