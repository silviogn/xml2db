require 'ffi'

require 'mach'
require 'mach/functions'

include Mach
include Mach::Functions

def setup_recv_port
  port = new_memory_pointer :mach_port_t
  mach_port_allocate(mach_task_self, :receive, port)
  p = port.get_uint(0)
  mach_port_insert_right(mach_task_self, p, p, :make_send)
  p
end

def send_port(remote_port, port)
  puts "send_port: (in #{mach_task_self}) sending #{port} -> #{remote_port}"
  msg = FFI::Struct.new(nil,
                        :header, MsgHeader,
                        :body, MsgBody,
                        :task_port, MsgPortDescriptor)
  msg[:header].tap do |h|
    h[:remote_port] = remote_port
    h[:local_port] = 0
    h[:bits] = (MachMsgType[:copy_send] | (0 << 8)) | 0x80000000 # MACH_MSGH_BITS_COMPLEX
    h[:size] = msg.size
  end

  msg[:body][:descriptor_count] = 1
  
  msg[:task_port].tap do |p|
    p[:name] = port
    p[:disposition] = MachMsgType[:copy_send]
    p[:type] = 0 # MACH_MSG_PORT_DESCRIPTOR;
  end

  mach_msg_send(msg)
end

def recv_port(recv_port)
  msg = FFI::Struct.new(nil,
                        :header, MsgHeader,
                        :body, MsgBody,
                        :task_port, MsgPortDescriptor,
                        :trailer, MsgTrailer)

  mach_msg(msg, 2, 0, msg.size, recv_port, 0, 0)

  msg.size.times do |i|
    print "%02x " % msg.to_ptr.get_uint8(i)
  end
  puts

  msg[:task_port][:name]
end

def sampling_fork
  parent_recv_port = setup_recv_port
  task_set_special_port(mach_task_self, :bootstrap, parent_recv_port)

  fork do
    parent_recv_port_p = new_memory_pointer :mach_port_t
    task_get_special_port(mach_task_self, :bootstrap, parent_recv_port_p)
    parent_recv_port = parent_recv_port_p.get_uint(0)
    puts "child self:#{mach_task_self} parent_recv:#{parent_recv_port}"

    child_recv_port = setup_recv_port
    puts "child sending #{mach_task_self}"
    send_port(parent_recv_port, mach_task_self)
  end

  task_set_special_port(mach_task_self, :bootstrap, Mach::Functions::bootstrap_port)
  child_task = recv_port(parent_recv_port)
  puts "parent received #{child_task}"
end

sampling_fork
