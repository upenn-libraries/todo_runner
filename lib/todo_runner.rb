require "todo_runner/version"

module TodoRunner

  @registry = {}

  def self.define &block
    task_proxy = TaskProxy.new
    task_proxy.instance_eval &block
  end

  def self.registry
    @registry
  end

  class TaskProxy
    def task name, options={}
      task = lambda {
        "OK, defining task #{name.inspect} with options: #{options}"
      }
      TodoRunner.registry[name] = task
    end
  end
end
