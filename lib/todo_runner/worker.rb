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

    attr_reader :task
    attr_reader :path
    attr_reader :todo_file
    attr_reader :outcome

    ##
    # @param [TodoRunner::Task] task
    # @param [TodoRunner::TodoFile] todo_file
    def initialize task:, todo_file:
      @task      = task
      @todo_file = todo_file
      @path      = @todo_file.todo_path
      @outcome   = false
    end

    def run
      rename_file task.name, 'running'
      # context = TaskContext.new todo_file: todo_file, path: path
      @outcome = task.run todo_file
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
      return path if path == new_name

      FileUtils.mv path, new_name
      @path = new_name
    end

    def new_name task_name, status
      "#{path.sub(/[^.]+$/, '')}#{new_ext task_name, status}"
    end

    def new_ext task_name, status
      return task_name if DEFAULT_TASKS.include? task_name
      [task_name, status].join '-'
    end
  end
end