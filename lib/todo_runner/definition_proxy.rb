module TodoRunner
  class DefinitionProxy
    ##
    # Set the task to start with
    # @param [Symbol] name the name of the start task
    def start name
      TodoRunner.start = name
    end

    ##
    # Create and register the task
    def task name, options={}, &block
      task = Task.new name, options, &block
      TodoRunner.registry[name] = task
    end
  end
end