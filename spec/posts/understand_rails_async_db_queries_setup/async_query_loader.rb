require "concurrent/executor/thread_pool_executor"

class AsyncQueryLoader
  # A very very stripped down version of ActiveRecord::FutureResult.
  # Mainly, all the error handling is removed. Who needs that, right?
  class FutureResult
    # Everything except the db pool is just pass through to the low level execution method.
    def initialize(database_connection_pool, *args, **kwargs)
      @pool = database_connection_pool
      @mutex = Mutex.new
      @pending = true

      @args = args
      @kwargs = kwargs
    end

    def execute_or_skip
      return unless @pending

      @pool.with_connection do |connection|
        # If someone already has the mutex they're executing the query so we
        # don't need to do anything.
        return unless @mutex.try_lock
        begin
          # Check again if it is pending in case it changed while we were
          # entering the mutex.
          execute_query(connection) if @pending
        ensure
          @mutex.unlock
        end
      end
    end

    def result
      if @pending
        # If query is currently being executed the executing thread will hold the mutex.
        # So the way we actually wait for execution to finish is by
        # waiting to enter the mutex.
        @mutex.synchronize do
          # Check again if it is pending in case it changed while we were
          # entering the mutex.
          execute_query(@pool.connection) if @pending
        end
      end
      @result
    end

    private

    def execute_query(connection)
      @result = connection.internal_exec_query(*@args, **@kwargs)
    ensure
      @pending = false
    end
  end

  def initialize
    # These are the default settings that Rails will use.
    @async_executor = Concurrent::ThreadPoolExecutor.new(
      min_threads: 0,
      max_threads: 4, # The default value if you don't set global_executor_concurrency
      max_queue: 16, # Rails sets the queue at 4 x max_threads.
      fallback_policy: :caller_runs # If queue is full, run it right away
    )
  end

  def run_async(query)
    connection = ActiveRecord::Base.connection
    sql, binds, _preparable = connection.send(:to_sql_and_binds, query.arel)
    future_result = FutureResult.new(connection.pool, sql, "Name", binds, prepare: false)
    @async_executor.post { future_result.execute_or_skip }
    future_result
  end
end
