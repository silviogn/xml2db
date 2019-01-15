require 'ffi'

module LibC
  extend FFI::Library

  ffi_lib FFI::Library::LIBC

  attach_variable :errno, :int

  attach_function :mmap, [:pointer, :size_t, :int, :int, :int, :off_t], :pointer
  attach_function :munmap, [:pointer, :size_t], :int

  attach_function :ftruncate, [:int, :off_t], :int

  class << self
    def call(err_msg = 'error in system call', &block)
      ret = yield
      err = LibC.errno

      if ret.kind_of?(Fixnum) and ret < 0
        raise SystemCallError.new(err_msg, err)
      end
      
      ret
    end
  end
end

module RT
  extend FFI::Library

  ffi_lib 'rt'

  attach_function :shm_open, [:string, :int, :mode_t], :int
  attach_function :shm_unlink, [:string], :int
end

module PSem
  extend FFI::Library

  lib = File.join(File.expand_path(File.dirname(__FILE__)),
                  'process_shared/libpsem.' + FFI::Platform::LIBSUFFIX)
  ffi_lib lib

  attach_function :psem_alloc, [], :pointer
  attach_function :psem_free, [:pointer], :void

  attach_function :psem_open, [:pointer, :string, :uint, :uint], :int
  attach_function :psem_close, [:pointer], :int
  attach_function :psem_unlink, [:string], :int
  attach_function :psem_post, [:pointer], :int
  attach_function :psem_wait, [:pointer], :int
  attach_function :psem_trywait, [:pointer], :int
  attach_function :psem_timedwait, [:pointer, :pointer], :int
  attach_function :psem_getvalue, [:pointer, :pointer], :int

  attach_function :bsem_alloc, [], :pointer
  attach_function :bsem_free, [:pointer], :void

  attach_function :bsem_open, [:pointer, :string, :uint, :uint], :int
  attach_function :bsem_close, [:pointer], :int
  attach_function :bsem_unlink, [:string], :int
  attach_function :bsem_post, [:pointer], :int
  attach_function :bsem_wait, [:pointer], :int
  attach_function :bsem_trywait, [:pointer], :int
  attach_function :bsem_timedwait, [:pointer, :pointer], :int
  attach_function :bsem_getvalue, [:pointer, :pointer], :int

  class << self
    include PSem

    def test
      bsem = bsem_alloc()

      class << bsem
        def value
          @int ||= FFI::MemoryPointer.new(:int)
          LibC.call { PSem.bsem_getvalue(self, @int) }
          @int.get_int(0)
        end
      end

      puts "alloc'ed at #{bsem.inspect}"
      puts LibC.call { bsem_open(bsem, "foobar", 1, 1) }
      puts "opened at #{bsem.inspect}"
      puts LibC.call { bsem_unlink("foobar") }
      puts "unlinked"

      puts "waiting for sem..."
      puts "value is #{bsem.value}"
      LibC.call { bsem_wait(bsem) }
      puts "acquired!"
      puts "value is #{bsem.value}"
      LibC.call { bsem_post(bsem) }
      puts "posted!"
      puts "value is #{bsem.value}"

      puts LibC.call { bsem_close(bsem) }
      bsem_free(bsem)
    end
  end
end

module PThread
  extend FFI::Library

  ffi_lib '/lib/x86_64-linux-gnu/libpthread-2.13.so' # 'pthread'

  attach_function :pthread_mutex_init, [:pointer, :pointer], :int
  attach_function :pthread_mutex_lock, [:pointer], :int
  attach_function :pthread_mutex_trylock, [:pointer], :int
  attach_function :pthread_mutex_unlock, [:pointer], :int
  attach_function :pthread_mutex_destroy, [:pointer], :int

  attach_function :pthread_mutexattr_init, [:pointer], :int
  attach_function :pthread_mutexattr_settype, [:pointer, :int], :int
  attach_function :pthread_mutexattr_gettype, [:pointer, :pointer], :int

  attach_function :pthread_mutexattr_setpshared, [:pointer, :int], :int

  class << self
    def call(err_msg = 'error in pthreads', &block)
      ret = yield
      raise SystemCallError.new(err_msg, ret) unless ret == 0
    end
  end

  module Helper
    extend FFI::Library

    # FIXME: this might not alwasy be ".so"
    lib = File.join(File.expand_path(File.dirname(__FILE__)), 'pthread_sync_helper.so')
    ffi_lib lib

    attach_variable :sizeof_pthread_mutex_t, :size_t
    attach_variable :sizeof_pthread_mutexattr_t, :size_t

    attach_variable :o_rdwr, :int
    attach_variable :o_creat, :int

    [:pthread_process_shared,

     :o_rdwr,
     :o_creat,

     :prot_read,
     :prot_write,
     :prot_exec,
     :prot_none,

     :map_shared,
     :map_private].each do |sym|
      attach_variable sym, :int
    end

    attach_variable :map_failed, :pointer

    PTHREAD_PROCESS_SHARED = pthread_process_shared

    O_RDWR = o_rdwr
    O_CREAT = o_creat

    PROT_READ = prot_read
    PROT_WRITE = prot_write
    PROT_EXEC = prot_exec
    PROT_NONE = prot_none

    MAP_FAILED = map_failed
    MAP_SHARED = map_shared
    MAP_PRIVATE = map_private
  end

  class Mutex
    include PThread
    include PThread::Helper

    class << self
      def alloc
        FFI::MemoryPointer.new(Helper.sizeof_pthread_mutex_t)
      end
    end

    def initialize(mutex = Mutex.alloc, attr = nil)
      @mutex = mutex
      PThread.call { pthread_mutex_init(@mutex, attr) }
    end

    def destroy
      PThread.call { pthread_mutex_destroy(@mutex) }
    end

    def lock
      PThread.call { pthread_mutex_lock(@mutex) }
    end

    def try_lock
      PThread.call { pthread_mutex_trylock(@mutex) }
    end

    def unlock
      PThread.call { pthread_mutex_unlock(@mutex) }
    end
  end

  class MutexAttr
    include PThread
    include PThread::Helper

    class << self
      def alloc
        FFI::MemoryPointer.new(Helper.sizeof_pthread_mutexattr_t)
      end
    end

    def initialize(ptr = MutexAttr.alloc)
      puts "have #{ptr}"
      @ptr = ptr
      PThread.call { pthread_mutexattr_init(@ptr) }
      self.type = type if type
    end

    def pointer
      @ptr
    end

    def pshared=(val)
      PThread.call { pthread_mutexattr_setpshared(@ptr, val) }
    end

    def type=(type)
      PThread.call { pthread_mutexattr_settype(@ptr, type) }
    end

    def type
      t = FFI::MemoryPointer.new(:int)
      PThread.call { pthread_mutexattr_gettype(@ptr, t) }
      t.get_int(0)
    end
  end

  class Int < FFI::Struct
      layout :val => :int
  end

  class << self
    include Helper

    def test
      puts "hi #{Helper.sizeof_pthread_mutex_t}"
      puts Mutex.new


      fd = LibC.call { RT.shm_open("/foo", O_CREAT | O_RDWR, 0777) }
      LibC.call { LibC.ftruncate(fd, 100) }
      pointer = LibC.mmap(nil, 100, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
      puts pointer
      puts pointer == MAP_FAILED
      puts MAP_FAILED

      attr = MutexAttr.new
      attr.pshared = PTHREAD_PROCESS_SHARED

      mutex = Mutex.new(pointer, attr.pointer)


      fd = LibC.call { RT.shm_open("/someint", O_CREAT | O_RDWR, 0777) }
      LibC.call { LibC.ftruncate(fd, 100) }
      pointer = LibC.mmap(nil, 100, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
      abort "failed" if pointer == MAP_FAILED

      value = Int.new(pointer)
      value[:val] = 0
      puts "int[0]: #{value[:val]}"

      puts "parent has mutex #{mutex}"

      n = 10000

      child = fork do
        puts "child and I have mutex: #{mutex}"

        n.times do |i|
          mutex.lock
          value[:val] = (value[:val] + 1)
          mutex.unlock
        end
      end

      n.times do |i|
        mutex.lock
        value[:val] = (value[:val] + 1)
        mutex.unlock
      end

      Process.wait(child)

      puts "value is now #{value[:val]}"
    end
  end
end
