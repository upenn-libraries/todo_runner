module TodoRunner
  class DefinitionProxy
    ##
    # Set the task to start with
    # @param [Symbol] name the name of the start task
    def start name
      TodoRunner.start = name
    end

    ##
    # @return [Tempfile] the data of the current +*.todo+ file
    def todo_data
      TodoRunner.todo_data
    end

    ##
    # Create and register the task
    def task name, options={}, &block
      task = Task.new name, options, &block
      TodoRunner.registry[name] = task
    end
  end
end