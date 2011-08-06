require "test/unit"
require "../lib/events"
require "stringio"

class TestEvents < Test::Unit::TestCase
  
  def test_emit_error_raises_without_handler
    emitter = Events::EventEmitter.new
    
    assert_raise(Events::UncaughtError) {emitter.emit(:error)}
    assert_raise(Events::UncaughtError) {emitter.emit(:error, "error")}
    assert(Events::UncaughtError < RuntimeError, "should be a subclass")
    assert_raise(StandardError) {emitter.emit(:error, StandardError.new("error"))}
    assert_raise(StandardError) {emitter.emit(:error, StandardError, "error")}
  end
  
  def test_emit_error_raises_without_handler_with_correct_message
    emitter = Events::EventEmitter.new
    
    begin
      emitter.emit(:error)
    rescue => e
      assert_equal("Uncaught, unspecified 'error' event.", e.message)
    end
    
    begin
      emitter.emit(:error, "test error message")
    rescue => e
      assert_equal("test error message", e.message)
    end
    
    begin
      emitter.emit(:error, StandardError.new("error test message"))
    rescue => e
      assert_equal("error test message", e.message)
    end
    
    begin
      emitter.emit(:error, StandardError, "message test error")
    rescue => e
      assert_equal("message test error", e.message)
    end
  end
  
  def test_any_listener_that_responds_to_call_is_accepted
    emitter = Events::EventEmitter.new
    block_result, proc_result, lambda_result = nil
    stringio = StringIO.new
    object = Object.new
    class << object
      attr_reader :result
      def call
        @result = true
      end
    end
    
    emitter.add_listener(:block) {block_result = true}
    emitter.emit(:block)
    assert(block_result, "block not called")
    
    emitter.add_listener(:proc, Proc.new {proc_result = true})
    emitter.emit(:proc)
    assert(proc_result, "proc not called")
    
    emitter.add_listener(:lambda, lambda {lambda_result = true})
    emitter.emit(:lambda)
    assert(lambda_result, "lambda not called")
    
    emitter.add_listener(:method, stringio.method(:puts))
    emitter.emit(:method)
    assert_equal("\n", stringio.string)
    
    emitter.add_listener(:object, object)
    emitter.emit(:object)
    assert(object.result, "object not called")
  end
  
  def test_any_once_listener_that_responds_to_call_is_accepted
    emitter = Events::EventEmitter.new
    block_result, proc_result, lambda_result = nil
    stringio = StringIO.new
    object = Object.new
    class << object
      attr_reader :result
      def call
        @result = true
      end
    end
    
    emitter.once(:block) {block_result = true}
    emitter.emit(:block)
    assert(block_result, "block not called")
    
    emitter.once(:proc, Proc.new {proc_result = true})
    emitter.emit(:proc)
    assert(proc_result, "proc not called")
    
    emitter.once(:lambda, lambda {lambda_result = true})
    emitter.emit(:lambda)
    assert(lambda_result, "lambda not called")
    
    emitter.once(:method, stringio.method(:puts))
    emitter.emit(:method)
    assert_equal("\n", stringio.string)
    
    emitter.once(:object, object)
    emitter.emit(:object)
    assert(object.result, "object not called")
  end
  
  def test_listener_is_required_to_respond_to_call
    emitter = Events::EventEmitter.new
    
    assert_raise(ArgumentError) {emitter.on(:test)}
    assert_raise(ArgumentError) {emitter.on(:test, "foo")}
    assert_raise(ArgumentError) {emitter.once(:test)}
    assert_raise(ArgumentError) {emitter.once(:test, "foo")}
  end
  
  def test_multi_arguments
    emitter = Events::EventEmitter.new
    
    emitter.on(:block) do |a, b|
      assert_equal("a", a)
      assert_equal("b", b)
    end
    
    emitter.emit(:block, "a", "b")
    
    emitter.on(:lambda, lambda do |a, b|
      assert_equal("a", a)
      assert_equal("b", b)
    end)
    
    emitter.emit(:lambda, "a", "b")
  end
  
  def test_multi_arguments_once
    emitter = Events::EventEmitter.new
    
    emitter.once(:block) do |a, b|
      assert_equal("a", a)
      assert_equal("b", b)
    end
    
    emitter.emit(:block, "a", "b")
    
    emitter.once(:lambda, lambda do |a, b|
      assert_equal("a", a)
      assert_equal("b", b)
    end)
    
    emitter.emit(:lambda, "a", "b")
  end
  
end
