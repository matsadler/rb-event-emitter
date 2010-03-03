require "test/unit"
require "../lib/events"

# Tests transliterated from javascript originals at http://github.com/ry/node/
class TestEventEmitter < Test::Unit::TestCase
  
  # /test/simple/test-event-emitter-add-listeners.js
  def test_event_emitter_add_listeners
    e = Events::EventEmitter.new
    
    events_new_listener_emited = []
    times_hello_emited = 0
    
    e.add_listener(:new_listener) do |event, listener|
      puts "new_listener: #{event}"
      events_new_listener_emited.push(event)
    end
    
    e.add_listener(:hello) do |a, b|
      puts "hello"
      times_hello_emited += 1
      assert_equal("a", a)
      assert_equal("b", b)
    end
    
    puts "start"
    
    e.emit(:hello, "a", "b")
    
    assert_equal([:hello], events_new_listener_emited)
    assert_equal(1, times_hello_emited)
  end
  
  # /test/simple/test-event-emitter-modify-in-emit.js
  def test_event_emitter_modify_in_emit
    callbacks_called = []
    
    e = Events::EventEmitter.new
    
    @callback1 = Proc.new do
      callbacks_called.push(:callback1)
      e.add_listener(:foo, &@callback2)
      e.remove_listener(:foo, @callback1)
    end
    
    @callback2 = Proc.new do
      callbacks_called.push(:callback2)
      e.remove_listener(:foo, @callback2)
    end
    
    e.add_listener(:foo, &@callback1)
    assert_equal(1, e.listeners(:foo).length)
    
    e.emit(:foo)
    assert_equal(1, e.listeners(:foo).length)
    assert_equal([:callback1], callbacks_called)
    
    e.emit(:foo)
    assert_equal(0, e.listeners(:foo).length)
    assert_equal([:callback1, :callback2], callbacks_called)
    
    e.emit(:foo)
    assert_equal(0, e.listeners(:foo).length)
    assert_equal([:callback1, :callback2], callbacks_called)
  end
  
end