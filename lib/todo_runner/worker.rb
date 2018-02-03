require 'fileutils'

module TodoRunner
  class Worker

    attr_reader :task
    attr_reader :file
    attr_reader :outcome

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