---
layout: post
title:  "Understand Rails async database queries by reimplementing them in 51 lines of simple Ruby"
date:   2023-10-17
categories: articles
tags: ruby rails activerecord
---

*Psst, listen here: this post is really about [leaky abstractions](https://en.wikipedia.org/wiki/Leaky_abstraction){:target="_blank"} and programmer mental models but I'm hiding it very cunningly. Don't tell anyone.*

Rails 7.1. [added async variants of many convenience querying methods](https://edgeguides.rubyonrails.org/7_1_release_notes.html#active-record-api-for-general-async-queries){:target="_blank"}. This is wonderful, as Rails developers we are bound to reap nearly free performance benefits from using it *in the correct way*. Why are those last words italic? For most applications the database is the main shared point of failure between different HTTP requests. If one of your app processes doesn't play nice with the database it can affect the whole application in a bad way.

Good abstractions are an amazing time saver as long as we don't push them to their breaking point. The best way I know of how to avoid that is to have a good mental model of how it actually works. A great way to do that is to peel away layers from the abstraction and look at just the core mechanism making it work. With the new understanding we can go back to our abstraction with more confidence. So let's peel away the layers from ActiveRecord async queries!

## Setup

The plan is to take a simple query and recreate the happy path for the async logic in as few lines of code as possible. If you are interested in the breakdown of the logic and just want to see the final code you can [jump ahead](#code-section) or have a look at the accompanying gist[^1].

I am testing it within a single file, outside a normal Rails application to isolate just the async loading. For the database I'm using Postgres. Normally I'd use SQLite for an easier setup but for `load_async` we need to be talking to an external process that does the actual work so we can actually parallelise on the IO. Also, Postgres conveniently has the `pg_sleep` function which we can use to simulate a slow query.

We'll start by setting up a model class with a slow query scope:
```ruby
class User < ActiveRecord::Base;
  scope :slow, -> {
    where("SELECT true FROM pg_sleep(1)").limit(10)
  }
end

query = User.slow
```
Note that at this point, due to lazy loading nothing has actually happened, we just constructed a query object. If we called `query.load` it would load it synchronously. For async loading we'd instead call `query.load_async`.

## Peeling away the layers

I've read the original PRs that added the async loading functionality and used the debugger to dig down to the actual raw happy path logic. It weaves through 9 layers of function calls but it is actually surprisingly simple. Unraveled into a linear high level algorithm, this is how it works for a typical query selecting some records from the database:
1. The underlying Arel object is extracted from the query object and after some processing handed over to the low level `select_all` method on the connection object. The query object is no longer needed.
2. The underlying Arel object together with parameter bindings is compiled just like it would be with a regular query into a raw sql string. Arel object is no longer needed.
3. We're now deep in the database connection object and the raw sql and prepared bindings are passed to the private `select` method which finally creates a [promise like object](https://en.wikipedia.org/wiki/Futures_and_promises){:target="_blank"}. In Rails codebase it's called a "future result". In our most common case it's an instance of `ActiveRecord::FutureResult::SelectAll`. Like many promise object implementations it is essentially a small state machine tracking the state of the execution.
4. The future result object is scheduled for execution on a thread pool. In particular it uses the [ThreadPoolExecutor](https://ruby-concurrency.github.io/concurrent-ruby/master/file.thread_pools.html#ThreadPoolExecutor){:target="_blank"} from the excellent [concurrent_ruby gem](https://github.com/ruby-concurrency/concurrent-ruby){:target="_blank"}. The worker thread will checkout a connection from the shared db connection pool to run the query.
5. The future result object is then returned to the application code.

When the future result object is accessed (for example in a view for rendering, by calling `result` or `to_a` on the future result object) one of 3 things will happen:
1. **If the query was already executed in the background**, the future result object will have the values and will just return them immediately.
2. **If the query is currently being executed**, the current thread will wait for it to finish and return the result. Implementation detail: it does this by entering the same mutex as the one that the executing thread will take.
3. **If the query has not yet started executing**, it will execute it synchronously and return the result.

### The parts that we ignored
Of course, this is not the full functionality of the async loading implementation. As is often the case, the majority of the code is error handling and special cases:
- Checking if async is enabled and executing synchronously if it isn't.
- Checking if we are in a transaction and executing synchronously if we are. Since the async execution is done on a different thread  by a different db connection running it async would mean it's also running outside the transaction.
- Exiting early on some special conditions where the code can conclude there will be no results returned, like an empty query.
- Handling [eager loading](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations){:target="_blank"}.
- Sanitising sql against injection attacks.
- Handling prepared SQL statements.
- Skipping query cache in case of a `SELECT ... FOR UPDATE` query.
- Executing synchronously when concurrent connections are not supported at all, e.g. [with in an memory SQLite db](https://www.sqlite.org/inmemorydb.html){:target="_blank"}.

Subscribe to not miss the next teardown:
<script async data-uid="f43925b4ae" src="https://thoughtful-producer-2834.ck.page/f43925b4ae/index.js"></script>

## Assembling just the happy path {#code-section}
Now that we broke it down we can put it all together into a small piece of code that recreates the happy path functionality of `load_async`. Of course without the parts that we ignored in the analysis above.

This is true to how ActiveRecord works just stripped of everything except the happy path. It's 51 lines _excluding comments and blank lines_:
```ruby
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
```

With that, sans the parts that we ignored, we could, in theory, replace `query.load_async` with:
```ruby
async_loader = AsyncQueryLoader.new
result = async_loader.run_async(User.slow)
```

If you want to test it yourself, check out the gist[^1].

## The learnings

Now that we've laid the happy path bare some key failure modes become much clearer:
- If we **indiscriminately use async loading** everywhere we can end up **starving the database connection pool** causing it to be empty when another request tries to check out a thread. In a high traffic scenario this could end up causing long delays on the requests, high queueing on the app server and eventually making the application unusable. Make sure that you have enough database connections.
- In the case of **a threaded web server**, by default, the thread pool executor will be shared among the request handling threads. If we didn't **configure the concurrency correctly correctly** we could end up having very **unreliable performance** on an endpoint making using async loading. Imagine that we have two requests come in one right after the other and both want to schedule 4 heavy queries for async loading. You could see the first request taking up all 4 worker threads on the async executor, forcing the other request into synchronous execution. This could result in the same endpoint varying strangely in execution time. You can control this via the [global_executor_concurrency](https://edgeguides.rubyonrails.org/configuring.html#config-active-record-global-executor-concurrency){:target="_blank"} configuration setting (defaults to 4 as in the above code).

Until now in most cases when estimating how many database connections you needed you just had to worry about number of your background job worker threads and your total number of web serving threads. Now you need to also account for the threads that will be running the async queries. The formula is now:
```ruby
needed_db_connections =
  web_processes * number_of_threads_per_web_process
  + background_processes * number_of_threads_per_background_process
  + web_processes * global_executor_concurrency
```
Make sure that your database can open as many database connections as you need.

It's now also clearer what are the best places to use the async loading:
- Ideally you have a single query that takes up a large chunk of a particular controller action and you can async just that one.
- If you do need to use it more often on the same controller action, it is best if the action doesn't see too much traffic. For example, a rarely hit but heavy action is a good place.
- If you do need it on a higher traffic action **and** it is important to keep latency low on it, make sure to increase the `global_executor_concurrency` and to adjust maximum database connections so it can keep up.

Key infrastructure metrics to monitor after deploying a change making use of async loading are:
1. Count of active database connections. This one is critical and you want to see it stay below the maximum at all times.
2. The p75 and p90 on the endpoints using async loading. If you watch just the average you might see it go down and miss that outliers became worse.

*Now, if it leaks, you'll know where you really need to plug it.*

Related links:
- Paweł Urbanek has a [blog post](https://pawelurbanek.com/rails-load-async){:target="_blank"} on the same topic with a different angle.

[^1]: The gist with all of the code in a ready for testing state can [be found here](https://gist.github.com/radanskoric/48f1982f2fe80b7d3bb44680f6d292aa){:target="_blank"}.
