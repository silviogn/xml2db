[![Gem Version][gemv-img]][gemv]
[![Build Status][travis-img]][travis]
[![Dependency Status][gemnasium-img]][gemnasium]
[![Code Climate][codeclimate-img]][codeclimate]
[gemv]: https://rubygems.org/gems/process_shared
[gemv-img]: https://badge.fury.io/rb/process_shared.png
[travis]: https://travis-ci.org/pmahoney/process_shared
[travis-img]: https://travis-ci.org/pmahoney/process_shared.png
[gemnasium]: https://gemnasium.com/pmahoney/process_shared
[gemnasium-img]: https://gemnasium.com/pmahoney/process_shared.png
[codeclimate]: https://codeclimate.com/github/pmahoney/process_shared
[codeclimate-img]: https://codeclimate.com/github/pmahoney/process_shared.png

process_shared
==============

Concurrency primitives that may be used in a cross-process way to
coordinate share memory between processes.

FFI is used to access POSIX semaphore on Linux or Mach semaphores on
Mac.  Atop these semaphores are implemented ProcessShared::Semaphore,
ProcessShared::Mutex.  POSIX shared memory is used to implement
ProcessShared::SharedMemory.

On Linux, POSIX semaphores support `sem_timedwait()` which can wait on
a semaphore but stop waiting after a timeout.

Mac OS X's implementation of POSIX semaphores does not support
timeouts.  But, the Mach layer in Mac OS X has its own semaphores that
do support timeouts.  Thus, process_shared implements a moderate
subset of the Mach API, which is quite a bit different from POSIX.
Namely, semaphores created in one process are not available in child
processes created via `fork()`.  Mach does provide the means to copy
capabilities between tasks (Mach equivalent to processes).
process_shared overrides Ruby's `fork` methods so that semaphores are
copied from parent to child to emulate the POSIX behavior.

This is an incomplete work in progress.

License
-------

MIT

Install
-------

Install the gem with:

    gem install process_shared

Usage
-----

```ruby
require 'process_shared'

mutex = ProcessShared::Mutex.new
mem = ProcessShared::SharedMemory.new(:int)  # extends FFI::Pointer
mem.put_int(0, 0)

pid1 = fork do
  puts "in process 1 (#{Process.pid})"
  10.times do
    sleep 0.01
    mutex.synchronize do
      value = mem.get_int(0)
      sleep 0.01
      puts "process 1 (#{Process.pid}) incrementing"
      mem.put_int(0, value + 1)
    end
  end
end

pid2 = fork do
  puts "in process 2 (#{Process.pid})"
  10.times do
    sleep 0.01
    mutex.synchronize do
      value = mem.get_int(0)
      sleep 0.01
      puts "process 2 (#{Process.pid}) decrementing"
      mem.put_int(0, value - 1)
    end
  end
end

Process.wait(pid1)
Process.wait(pid2)

puts "value should be zero: #{mem.get_int(0)}"
```

Transfer Objects Across Processes
---------------------------------

```ruby
# allocate a sufficient memory block
mem = ProcessShared::SharedMemory.new(1024)

# sub process can write (serialize) object to memory (with bounds checking)
pid = fork do
  mem.write_object(['a', 'b'])
end

Process.wait(pid)

# parent process can read the object back (synchronizing access
# with a Mutex left as an excercie to reader)

mem.read_object.must_equal ['a', 'b']
```

Todo
----

* Test ConditionVariable
* Implement optional override of core Thread/Mutex classes
* Extend to win32?  (See Python's processing library)
* Add finalizer to Mutex? (finalizer on Semaphore objects may be enough) or a method to
  explicitly close and release resources?
* Test semantics of crashing processes who still hold locks, etc.
* Is SharedArray with Enumerable mixing sufficient Array-like interface?
