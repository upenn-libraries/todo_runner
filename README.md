# TodoRunner

Todo Runner is intended to manage a directory-based system of tasks. Files are
added to a directory with an extension of `.todo`. Code that uses todo-runner
specifies a series of tasks to be performed based on those files. Each todo
file may contain information to be used by your code. 

For example, consider the following example. Let's say we have a `cakes-to-bake`
directory with these files:

```bash
chocolate_cake.todo
carrot_cake.todo
```

The `chocolate_cake.todo` file may contain YAML (or any format our code wants),
like so:

```yaml
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
TodoRunner.define do 

  #TODO: Do we really need after(:each), as opposed to a final task?
  after(:each) do
    add_to_menu unless failed?
  end

  task :mix, on_fail: :FAIL, next_step: :bake do
    # mixing code
  end
  
  task :bake, on_fail: :FAIL, next_step: :cool do
    # baking code
  end
  
  TASK :cool, on_fail: :CONTINUE, next_step: :mix_icing do
    # 
  end
  
  task :mix_icing, on_fail: :FAIL, next_step: :ice_cake do
    # 
  end
  
  task :ice_cake, on_fail: :FAIL, next_step: :SUCCESS do
    #
  end
end
```

TODO: Describe return value of successful task (i.e., non-false)

As it runs each task, the framework manages the name of each `.todo` in the 
`cakes-to-bake` directory, first changing `.todo` to `.processing` for all 
files `*.todo` in the directory. Then it changes the file extensions according
to the current task, with the qualifiers `-running`, `-completed`, or `-failed`.
For example: `chocolate_cake.mix-running` and `chocolate_cake.mix-completed`.

TODO: Describe  default tasks (:STOP, :FAIL, :SUCCESS), including terminal tasks  

## Installation

TODO: No installation instructions yet.

## Usage

TODO: Write usage instructions here

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
