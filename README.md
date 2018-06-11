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

TodoRunner.define do
  # we have to say where to start
  start :mix

  task :mix, on_fail: :FAIL, next_step: :bake do |todo_file|
    data = YAML.load todo_file
    recipe = data['Ingredients']
    # mix the cake and implicitly return `true` on success; otherwise, task fails
  end

  task :bake, on_fail: :FAIL, next_step: :cool do |todo_file|
    data = YAML.load todo_file
    how_to_bake = data['Baking']
    # baking code and implicitly return `true` on success; otherwise, task fails
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
end

TodoRunner.run 'path/to/chocolate_cake.todo', 'path/to/carrot_cake.todo'
```

For the runner to proceed to the next step, a task must return a non-false
value; otherwise, the `:on_fail` task is run.

As it runs each task, the framework manages the name of each `.todo` in the
`cakes-to-bake` directory, first changing `.todo` to `.processing` for all
files `*.todo` in the directory. Then it changes the file extensions according
to the current task, with the qualifiers `-running`, `-completed`, or `-failed`.
For example: `chocolate_cake.mix-running` and `chocolate_cake.mix-completed`.

TODO: Describe default tasks (:STOP, :FAIL, :SUCCESS), including terminal tasks

## Installation

TODO: No installation instructions yet.

## Usage

TODO: Write usage instructions here

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
