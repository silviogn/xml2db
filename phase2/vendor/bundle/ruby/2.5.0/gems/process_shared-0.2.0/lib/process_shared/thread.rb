module ProcessShared
  # API-compatible with Ruby Thread class but using ProcessShared
  # primitives instead (i.e. each Thread will be a separate OS
  # process).
  class Process
    class << self
      # How the heck will I implement this...
      def abort_on_exception
      end

      def abort_on_exception=(val)
      end

      # This can't really work since each thread is a separate process..
      def current
      end

      def kill(process)
        ::Process.kill(process.pid)
      end
    end

    def join(limit = nil)
      if limit
      else
        ::Process.wait(pid)
      end
    end
  end
end
