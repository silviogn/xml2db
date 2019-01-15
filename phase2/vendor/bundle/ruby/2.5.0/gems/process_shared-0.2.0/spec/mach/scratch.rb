require 'mach'
require 'mach/functions'

include Mach
include Mach::Functions

sem = Semaphore.new(:value => 0)

# puts ">parent has sem #{sem.port}"

# fork do
#   sleep 2                         # make parent wait a bit
#   puts "in child..."
#   sem = Mach::Semaphore.new(:port => Mach::Task.self.get_bootstrap_port)
#   puts "child signaling sem #{sem.port}"
#   sem.signal
# end

# puts ">parent waiting on sem..."
# sem.wait
# puts ">parent done waiting!"

def struct(*layout)
  yield FFI::Struct.new(nil, *layout)
end

puts "sizeof MsgPortDescriptor: #{MsgPortDescriptor.size}"
port = Port.new
port.insert_right(:make_send)

Task.self.set_bootstrap_port(port)
puts "> self:#{mach_task_self} bootstrap:#{port.port} (#{Mach::Functions::bootstrap_port.to_i})"

child = fork do
  parent_port = Task.self.get_bootstrap_port
  puts "in child... self:#{mach_task_self} bootstrap:#{parent_port.port}"

  #port = Port.new
  #port.copy_send(parent_port)

  #sem = port.receive_right

  Task.self.copy_send(parent_port)
  puts "child sleeping"
  sleep 2
  puts "child signaling semaphore"
  sem.signal
  puts "child out"
  sleep 2
end

sleep 0.1
if Process.wait(child, Process::WNOHANG)
  puts "child died!"
  #exit 1
end

Task.self.set_bootstrap_port(Mach::Functions::bootstrap_port)
child_task_port = port.receive_right
puts "parent: child task port is #{child_task_port}"

sem.insert_right(:copy_send, :ipc_space => child_task_port)

puts "parent waiting"
sem.wait
puts "parent done waiting!"

