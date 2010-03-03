module Events
  module Emitter
    def listeners(event)
      (@listeners ||= Hash.new {|hash, key| hash[key] = []})[event]
    end
    
    def emit(event, *args)
      listeners(event).each do |listener|
        listener.call(*args)
      end.any?
    end
    
    def add_listener(event, &block)
      emit(:new_listener, event, block)
      listeners(event).push(block)
      self
    end
    
    def remove_listener(event, proc)
      listeners(event).delete(proc)
      self
    end
  end
  
  class EventEmitter
    include Emitter
  end
end