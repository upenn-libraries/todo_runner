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
  # @attr_reader [String] file path to the +*.todo+ file
  # @attr_reader [String] outcome the result of the process +completed+ or +failed+
  class Worker

    attr_reader :task
    attr_reader :file
    attr_reader :outcome

    ##
    # @param [TodoRunner::Task] task the Task to run
    # @param [String] file path to the +*.todo+ file
    def initialize task, file
      @task    = task
      @file    = file
      @outcome = false
    end

    def run
      rename_file task.name, 'running'
      @outcome = task.run
      out_status = @outcome ? 'completed' : 'failed'
      rename_file task.name, out_status
      @outcome
    end

    def succeeded?
      @outcome
    end

    def failed?
      !succeeded?
    end

    private

    def rename_file task_name, status
      new_name = new_name task_name, status
      return file if file == new_name

      FileUtils.mv file, new_name
      @file = new_name
      # binding.pry
    end

    def new_name task_name, status
      "#{file.sub(/[^.]+$/, '')}#{new_ext task_name, status}"
    end

    def new_ext task_name, status
      return task_name if DEFAULT_TASKS.include? task_name
      [task_name, status].join '-'
    end
  end
end