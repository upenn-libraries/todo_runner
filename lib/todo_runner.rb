require 'tempfile'
require 'todo_runner/version'
require 'todo_runner/task'
require 'todo_runner/definition_proxy'
require 'todo_runner/worker'
require 'todo_runner/todo_file'

module TodoRunner
  # TODO: Add :CONTINUE behavior
  # TODO: ?? Add before, after callbacks before|after(:each|:all)
  # TODO: Decide how to handle errors and falling back to errors
  # TODO: Logging????

  DEFAULT_TASKS = %i{ STOP SUCCESS FAIL CONTINUE }.freeze
  TERMINAL_TASKS = %i{ STOP SUCCESS FAIL }

  @registry  = {}
  @start     = nil
  @todo_file = nil

  @registry[:STOP] = Task.new :STOP do
    puts 'STOPPING'
  end

  @registry[:SUCCESS] = Task.new :SUCCESS do
    puts 'SUCCESS!'
  end

  @registry[:FAIL] = Task.new :FAIL do
    puts 'FAILED!'
  end

  @registry[:CONTINUE] = Task.new :CONTINUE do
    puts 'CONTINUING!'
  end

  @registry[:ERROR] = Task.new :ERROR do
    puts 'ERROR!'
  end

  def self.define &block
    definition_proxy = DefinitionProxy.new
    definition_proxy.instance_eval &block
  end

  def self.registry
    @registry
  end

  def self.start= name
    @start = name
  end

  def self.start
    @start
  end

  def self.terminal_task? name
    return true if name.nil?
    TERMINAL_TASKS.include? name
  end

  def self.run *paths
    paths.each do |path|
      run_one path
    end
  end

  def self.next_step task, outcome
    name = outcome ? task.next_step : task.on_fail_step
    return unless name
    raise "No task found named #{name.inspect}" unless registry.include? name
    registry[name]
  end

  protected

  def self.run_one path
    task    = registry[@start]
    result  = run_task task: task, path: path
    task    = next_step task, result[:outcome]

    loop do
      result = run_task task: task, path: result[:file]
      break if terminal_task? task.name
      task = next_step task, result[:outcome]
      break if task.nil?
    end
  end

  private

  def self.run_task task:, path:
    todo_file = TodoFile.new path, task.name
    worker    = TodoRunner::Worker.new task: task, todo_file: todo_file
    worker.run
    {file: worker.path, outcome: worker.outcome }
  end
end
