# A ThreadedWorker allows a queue of work to be spread over a pool of worker
# threads.
class ThreadedWorker
  N_THREADS = 6

  # Every element of queue will be yieled to a work block in some thread.
  # Needless to say, work_block must be thread safe (e.g. have no shared state
  # from its lexical scope)
  def initialize(queue, mode = :multiprocess, &work_block)
    @queue = queue
    @work_block = work_block
    @mode = mode
  end

  def run
    self.send("run_#{@mode}".to_sym)
  end

  def run_multithread
    threads = []
    index = 0
    index_lock = Mutex.new
    N_THREADS.times do |thread_i|
      threads << Thread.new do
        while true
          current = nil
          index_lock.synchronize {
            current_index = index
            Thread.exit if current_index == @queue.length
            current = @queue[current_index]
            index += 1
          }
          @work_block.call(current, thread_i)
        end
      end
    end

    threads.each(&:join)
  end

  def run_multiprocess
    pids = []
    index = ProcessShared::SharedMemory.new(:int)
    index.put_int(0, 0)
    index_lock = ProcessShared::Mutex.new
    N_THREADS.times do |thread_i|
      pids << fork do
        while true
          current = nil
          index_lock.synchronize {
            current_index = index.get_int(0)
            Process.exit if current_index == @queue.length
            current = @queue[current_index]
            index.put_int(0, current_index + 1)
          }
          @work_block.call(current, thread_i)
        end
      end
    end

    pids.each { |pid| Process.wait(pid) }
  end
end
