require 'socket'
require '../lib/events'

$connections = []

class TCPSocket
  include Events::Emitter
  
  alias original_initialize initialize
  def initialize(*args)
    original_initialize(*args)
    @write_queue = []
    $connections.push(self)
  end
  
  def notify_readable
    emit(:data, read_nonblock(1024))
  rescue EOFError
    $connections.delete(self)
    emit(:end)
  end
  
  def notify_writeable
    if @write_queue.any?
      write_nonblock(@write_queue.shift)
    end
  end
  
  def write(data)
    @write_queue.push(data)
    data.length
  end
  
  def pending_write?
    @write_queue.any?
  end
end

class TCPServer
  include Events::Emitter
  
  alias original_initialize initialize
  def initialize(*args)
    original_initialize(*args)
    $connections.push(self)
  end
  
  def notify_readable
    connection = accept_nonblock
    connection.instance_variable_set(:"@write_queue", [])
    $connections.push(connection)
    emit(:connection, connection)
    connection.emit(:connect)
  end
  
  def pending_write?
    false
  end
end

server = TCPServer.new("localhost", 7000)

server.on(:connection) do |connection|
  connection.on(:data) do |data|
    connection.write(data)
  end
end

loop do
  to_read = $connections
  to_write = $connections.select {|c| c.pending_write?}
  readable, writeable = select(to_read, to_write)
  readable.each {|r| r.notify_readable} if readable
  writeable.each {|w| w.notify_writeable} if writeable
end