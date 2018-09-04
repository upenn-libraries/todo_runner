require 'fileutils'
require 'tempfile'

module TodoRunner
  ##
  # Worker to manage and execute a Task for a +*.todo+ file. Runs the task,
  # manages +.todo+ file name, and returns the task outcome (+completed+ or
  # +failed+).
  #
  # For a +.todo+ file named +cake.todo+, and task named +mix+, the extension is
  # renamed as the process runs, as follows:
  #
  # - +cake.mix-running+ task in process
  # - +cake.mix-completed+ task completed
  # - +cake.mix-failed+ the task failed
  #
  # @attr_reader [TodoRunner::Task] task the task to run
  # @attr_reader [String] path path to the +*.todo+ file
  # @attr_reader [String] outcome the result of the process +completed+ or +failed+
  class Worker
    include TodoRunner::FileRenaming

    attr_reader :task
    attr_reader :path
    attr_reader :todo_file
    attr_reader :outcome

    ##
    # @param [TodoRunner::Task] task
    # @param [String] path
    def initialize task:, path:
      @task      = task
      @path      = path
      @outcome   = false
    end

    ##
    # Run the worker.
    #
    # @return [Boolean] outcome
    def run
      @path      = Worker.rename_file path, task.name, 'running'
      @todo_file = TodoRunner::TodoFile.new path, task.name
      begin
        @outcome   = task.run todo_file
      ensure
        todo_file.close if todo_file
      end
      out_status = @outcome ? 'completed' : 'failed'
      @path      = Worker.rename_file path, task.name, out_status
      @outcome
    end

    ##
    # @return [Boolean]
    def succeeded?
      return true if @outcome
    end

    ##
    # Convenience method for +!self.succeeded?+
    #
    # @return [Boolean]
    def failed?
      !succeeded?
    end

  end
end
