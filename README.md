# TodoRunner

Todo Runner is intended to manage a directory-based system of tasks. Files are
added to a directory with an extension of `.todo`. Code that uses todo-runner
specifies a series of tasks to be performed based on those files. Each todo
file may contain information to be used by your code. The `todo_file` is an
instance of TodoRunner::TodoFile, which delegates to a Ruby Tempfile. It adds
the accessors `:task_name` and `:todo_path`.


For example, consider the following example. Let's say we have a `cakes-to-bake`
directory with these files:

```bash
chocolate_cake.todo
carrot_cake.todo
```

The `todo` file can contain data. If so, to access the data,
you have to use the `todo_file` block argument for the `task` definitions
where you use it.

For example, the `chocolate_cake.todo` contains YAML (though it can be any
format you like):

```yml
Cake:
  Name: Chocolate cake
  Ingredients:
    sugar: 0.5 cups
    flour: 2 cups
    eggs: 1
    # etc.
  Baking:
    Temperature: 350
    Time: 25 minutes
Icing:
  Ingredients:
    Powdered_sugar: 1 cup
    # etc.
```

NB: I don't bake cakes. Don't judge me.

Our code to bake and ice the cakes would look like this:

```ruby
require 'yaml'
require 'logger'

# TodoRunner.define creates its own scope. Use constants to pass in outside
# objects and data. 
LOGGER         = Logger.new $stdout
LOGGER.level   = Logger::INFO

TodoRunner.define do

  # add some helper methods **inside** the todo_runner definition
  def serve_cakes
    # serve all the cakes we've made
  end
  
  def adjust_oven temp
    # adjust the oven temp
  end
  # we have to say where to start
  start :mix

  task :mix, on_fail: :FAIL, next_step: :bake do |todo_file|
    data = YAML.load todo_file
    LOGGER.info { "Mixing cake #{data.dig 'Name'}" }
    recipe = data['Ingredients']
    # mix cake and implicitly return `true` on success; otherwise, task fails
  end

  task :bake, on_fail: :FAIL, next_step: :cool do |todo_file|
    data = YAML.load todo_file
    LOGGER.info { "Baking cake #{data.dig 'Name'}" }
    how_to_bake = data['Baking']
    adjust_oven how_to_bake['Temperature']
    # bake cake and implicitly return `true` on success; otherwise, task fails
  end

  TASK :cool, on_fail: :STOP, next_step: :mix_icing do |todo_file|
    #
  end

  task :mix_icing, on_fail: :FAIL, next_step: :ice_cake do |todo_file|
    #
  end

  task :ice_cake, on_fail: :FAIL, next_step: :SUCCESS do |todo_file|
    #
  end
  
  # Run a task before anything starts
  before :all do
    # clean the work space
  end
  
  # Run a task after everything is complete
  after :all do
    serve_cakes
  end
end

TodoRunner.run 'path/to/chocolate_cake.todo', 'path/to/carrot_cake.todo'
```

For the runner to proceed to the next step, a task must return a non-false
value; otherwise, the `:on_fail` task is run.

As it runs each task, the framework manages the name of each `.todo` in the
`cakes-to-bake` directory, first changing `.todo` to `.processing` for all
files `*.todo` in the directory. Then it changes the file extension according to
the current task, with the qualifiers `-running`, `-completed`, or `-failed`.
For example: `chocolate_cake.mix-running`, `chocolate_cake.mix-completed`, and
`chocolate_cake.mix-failed`.

TODO: Describe default tasks (:STOP, :FAIL, :SUCCESS), including terminal tasks

## Hooks

At present the only task hooks are `before :all` and `after :all`.

## Installation

If you have todo-runner installed on a local gem server, you can add it to your 
`Gemfile`: 

```ruby
gem 'todo_runner'
```

or install it from the command line.

```ruby
gem install todo_runner
```

Otherwise,

```
git clone https://github.com/upenn-libraries/todo_runner.git
cd todo_runner
bundle install
bundle exec rake build
gem install --local pkg/todo_runner-0.3.1.gem
```

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
