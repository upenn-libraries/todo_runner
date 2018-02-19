module TodoRunner
  class DefinitionProxy
    VALID_INTERVALS = %i{ each_todo all }

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

    ##
    # Create an after callback.
    #
    # @param [Symbol] interval +:all+
    # @param [Hash] options
    # @option options [Symbol] :name optional callback name
    # @return [TodoCallback]
    def after interval, options = {}, &block
      callback = TodoCallback.new interval, options, &block
      TodoRunner.add_after_callback callback
    end

    ##
    # Create a before callback.
    #
    # @param [Symbol] interval +:all+
    # @param [Hash] options
    # @option options [Symbol] :name optional callback name
    # @return [TodoCallback]
    def before interval, options = {}, &block
      callback = TodoCallback.new interval, name, &block
      TodoRunner.add_before_callback callback
    end

  end # class DefinitionProxy
end
