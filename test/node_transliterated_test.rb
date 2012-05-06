require "test/unit"
require File.expand_path("../../lib/events", __FILE__)

# Tests transliterated from javascript originals at
# http://github.com/joyent/node/
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
    
    e.on(:hello) do |a, b|
      puts "hello"
      times_hello_emited += 1
      assert_equal("a", a)
      assert_equal("b", b)
    end
    
    puts "start"
    
    e.emit(:hello, "a", "b")
    
    
    # just make sure that this doesn't raise:
    f = Events::EventEmitter.new
    assert_nothing_raised {f.max_listeners = 0}
    
    assert_equal([:hello], events_new_listener_emited)
    assert_equal(1, times_hello_emited)
  end
  
  # /test/simple/test-event-emitter-check-listener-leaks.js
  def test_event_emitter_check_listener_leaks
    e = Events::EventEmitter.new
    
    # default
    10.times do
      e.on(:default) {}
    end
    assert(!e.listeners(:default).warned)
    e.on(:default) {}
    assert(e.listeners(:default).warned)
    
    # specific
    e.max_listeners = 5
    5.times do
      e.on(:specific) {}
    end
    assert(!e.listeners(:specific).warned)
    e.on(:specific) {}
    assert(e.listeners(:specific).warned)
    
    # only one
    e.max_listeners = 1
    e.on(:only_one) {}
    assert(!e.listeners(:only_one).warned)
    e.on(:only_one) {}
    assert(e.listeners(:only_one).warned)
    
    # unlimited
    e.max_listeners = 0
    1000.times do
      e.on(:unlimited) {}
    end
    assert(!e.listeners(:unlimited).warned)
  end
  
  # /test/simple/test-event-emitter-modify-in-emit.js
  def test_event_emitter_modify_in_emit
    callbacks_called = []
    
    e = Events::EventEmitter.new
    
    @callback1 = Proc.new do
      callbacks_called.push(:callback1)
      e.add_listener(:foo, &@callback2)
      e.add_listener(:foo, &@callback3)
      e.remove_listener(:foo, @callback1)
    end
    
    @callback2 = Proc.new do
      callbacks_called.push(:callback2)
      e.remove_listener(:foo, @callback2)
    end
    
    @callback3 = Proc.new do
      callbacks_called.push(:callback3)
      e.remove_listener(:foo, @callback3)
    end
    
    e.add_listener(:foo, &@callback1)
    assert_equal(1, e.listeners(:foo).length)
    
    e.emit(:foo)
    assert_equal(2, e.listeners(:foo).length)
    assert_equal([:callback1], callbacks_called)
    
    e.emit(:foo)
    assert_equal(0, e.listeners(:foo).length)
    assert_equal([:callback1, :callback2, :callback3], callbacks_called)
    
    e.emit(:foo)
    assert_equal(0, e.listeners(:foo).length)
    assert_equal([:callback1, :callback2, :callback3], callbacks_called)
    
    e.add_listener(:foo, &@callback1)
    e.add_listener(:foo, &@callback2)
    assert_equal(2, e.listeners(:foo).length)
    e.remove_all_listeners(:foo)
    assert_equal(0, e.listeners(:foo).length)
    
    # Verify that removing callbacks while in emit allows emits to propagate to
    # all listeners
    callbacks_called = []
    
    e.add_listener(:foo, &@callback2)
    e.add_listener(:foo, &@callback3)
    assert_equal(2, e.listeners(:foo).length)
    e.emit(:foo)
    assert_equal([:callback2, :callback3], callbacks_called)
    assert_equal(0, e.listeners(:foo).length)
  end
  
  # /test/simple/test-event-emitter-num-args.js
  def test_event_emitter_num_args
    e = Events::EventEmitter.new
    num_args_emited = []
    
    e.on(:num_args) do |*args|
      num_args = args.length
      puts "num_args: #{num_args}"
      num_args_emited.push(num_args)
    end
    
    puts "start"
    
    e.emit(:num_args)
    e.emit(:num_args, nil)
    e.emit(:num_args, nil, nil)
    e.emit(:num_args, nil, nil, nil)
    e.emit(:num_args, nil, nil, nil, nil)
    e.emit(:num_args, nil, nil, nil, nil, nil)
    
    assert_equal([0, 1, 2, 3, 4, 5], num_args_emited)
  end
  
  # /test/simple/test-event-emitter-once.js
  def test_event_emitter_once
    e = Events::EventEmitter.new
    times_hello_emited = 0
    
    e.once(:hello) do |a, b|
      times_hello_emited += 1
    end
    
    e.emit(:hello, "a", "b")
    e.emit(:hello, "a", "b")
    e.emit(:hello, "a", "b")
    e.emit(:hello, "a", "b")
    
    remove = Proc.new do
      flunk("once->foo should not be emitted")
    end
    
    e.once(:foo, remove)
    e.remove_listener(:foo, remove)
    e.emit(:foo)
    
    assert_equal(1, times_hello_emited)
  end
  
  # /test/simple/test-event-emitter-remove-all-listeners.js
  def test_event_emitter_remove_all_listeners
    listener = Proc.new {}
    
    e1 = Events::EventEmitter.new
    e1.add_listener(:foo, &listener)
    e1.add_listener(:bar, &listener)
    e1.remove_all_listeners(:foo)
    assert_equal([], e1.listeners(:foo))
    assert_equal([listener], e1.listeners(:bar))
    
    e2 = Events::EventEmitter.new
    e2.add_listener(:foo, &listener)
    e2.add_listener(:bar, &listener)
    e2.remove_all_listeners
    assert_equal([], e2.listeners(:foo))
    assert_equal([], e2.listeners(:bar))
  end
  
  # /test/simple/test-event-emitter-remove-listeners.js
  def test_event_emitter_remove_listeners
    count = 0
    
    listener1 = Proc.new do
      puts("listener1")
      count +=1
    end
    
    listener2 = Proc.new do
      puts("listener2")
      count +=1
    end
    
    listener3 = Proc.new do
      puts("listener3")
      count +=1
    end
    
    e1 = Events::EventEmitter.new
    e1.add_listener(:hello, &listener1)
    e1.remove_listener(:hello, listener1)
    assert_equal([], e1.listeners(:hello))
    
    e2 = Events::EventEmitter.new
    e2.add_listener(:hello, &listener1)
    e2.remove_listener(:hello, listener2)
    assert_equal([listener1], e2.listeners(:hello))
    
    e3 = Events::EventEmitter.new
    e3.add_listener(:hello, &listener1)
    e3.add_listener(:hello, &listener2)
    e3.remove_listener(:hello, listener1)
    assert_equal([listener2], e3.listeners(:hello))
  end
  
end