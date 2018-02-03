require 'todo_runner/version'
require 'todo_runner/task'
require 'todo_runner/definition_proxy'
require 'todo_runner/worker'

module TodoRunner

  DEFAULT_TASKS = %i{ STOP SUCCESS FAIL CONTINUE }.freeze
  # TODO: Add :CONTINUE task and behavior

  # TODO: Add #run_dir method

  # TODO: ?? Add before, after callbacks before|after(:each|:all)

  TERMINAL_TASKS = %i{ STOP SUCCESS FAIL }

  @registry = {}
  @start    = nil

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

  def self.run file
    @current_file = file

    task    = registry[@start]
    outcome = run_task task
    task    = next_step task, outcome

    loop do
      outcome = run_task task
      break if terminal_task? task.name
      task = next_step task, outcome
      break if task.nil?
    end
  end

  def self.next_step task, outcome
    name = outcome ? task.next_step : task.on_fail_step
    return unless name
    raise "No task found named #{name.inspect}" unless registry.include? name
    registry[name]
  end

  protected

  def self.current_file
    @current_file
  end

  def self.current_file= file
    @current_file = file
  end

  private

  def self.run_task task
    puts "File is: #{current_file}"
    worker = TodoRunner::Worker.new task, current_file
    worker.run
    self.current_file = worker.file
    puts "File is: #{current_file}"
    worker.outcome
  end


end


