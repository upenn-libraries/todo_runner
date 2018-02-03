module TodoRunner
  class DefinitionProxy
    def start name
      TodoRunner.start = name
    end

    def task name, options={}, &block
      task = Task.new name, options, &block
      TodoRunner.registry[name] = task
    end
  end
end