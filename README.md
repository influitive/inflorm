# Inflorm

*Simple Form Objects with validations and associations making no assumptions about persistence*

This is so little code you almost can't call it a library. It's simply a wrapper around Virtus
and ActiveModel validations, with an extra validation to allow for validating associations. I hesistated
to even make it a gem, but it's a pattern we use across multiple apps so it kind of made sense.

## Philosophy

After working on many massive rails apps, it's become clear that model validations can cause a lot
of headaches, particularly when you get into custom validations and conditional validations. At
Influitive, we now consider these types of validations on the model an anti-pattern and stick purely
to validations that support underlying database constraints. Validations such as `NOT NULL` and `UNIQUE`
make sense on the model. Validations such as `validate property x if it's a full moon` do NOT
make sense in the model as these are contextual to a particular use case. This use case should be
wrapped up in its own object and used to validate input *before* it hits your persistence layer.

## Why another form object library?

Again, I hardly consider this a library on its own, it's just a thin wrapper. We worked with
both [Reform](https://github.com/apotonick/reform) and [ActiveType](https://github.com/makandra/active_type)
and both always felt awkward to use and required a new dsl to understand.

- Reform feels weird to me because I generally just want params in and params out with validations
and param whitelisting. It requires however an underlying model to be passed in, then validated with
params separately passed in. It has a whole DSL for persistence which I never fully grasped, though
as the author states, it's optional to use.
- ActiveType is very much ActiveRecord dependent. It also unfortunately sticks to the Rails
`accepts_nested_attributes` paradigm which requires nesting to be done with a `{association_name}_attributes` key which I find annoying. (your public interface should NOT be determined by the framework you use under the hood).
Futhermore, for associations, it instantiates raw models as the children, as opposed to other form objects, which to me defeats the purpose of a form object library.

This is not to speak badly about either library. They both obviously suit the use-cases of the authors,
they just didn't suit our use-case.

## Usage

Since inflorm is nothing more than a thin wrapper over [Virtus](https://github.com/solnic/virtus)
and [ActiveModel::Validations](http://guides.rubyonrails.org/active_model_basics.html#validations).
As such, you can find advanced documentation on this sites, but a simple example would look like this:

```ruby
class ParentForm
  include Inflorm

  attribute :name,  String
  attribute :title, String

  attribute :child, ChildForm      # has_one association
  attribute :pets,  Array[PetForm] # has_many association

  validates :name,  presence: true
  validates :child, associated: true
  validates :pets,  associated: true
end

class ChildForm
  include Inflorm

  attribute :age, Integer

  validates :age, presence: true
end

class PetForm
  include Inflorm

  attribute :name,    String
  attribute :species, String

  validates :name,    presence: true
  validates :species, presence: true
end
```

Using those classes like so:

```ruby
  # Simple object
  p = Parent.new name: ''
  p.valid? # => false

  # Object with has_one association
  p = Parent.new name: 'x', child: {age: 123}
  p.child.class # => ChildForm
  p.valid? # => true

  # Object with has_many association
  p = Parent.new pets: [{species: 'dog', name: 'George'}, {species: 'cat', name: 'Fluffy'}]
  p.pets.class # => Array
  p.pets[0].class # => PetForm
  p.valid? # => true
```

## Persistence

Inflorm doesn't care about persistence. That's what your ORM is for (or appropriate
[Command](http://rom-rb.org/guides/basics/commands/),
[Repository](http://lotusrb.org/guides/models/repositories/) etc). Since it's just params in and
params out, you can just call `to_h` on your form object to get the validated, whitelisted params.
This means you don't need to use things like `strong_parameters`.

### Rails-like pattern
A common pattern in the rails world is to do something like:

```ruby
# some_controller.rb
if @my_object.save
  # do_something
else
  # something else
end
```

Inflorm includes a very simple implementation of `save` by allowing you to define a `persist!` method
on your form that will only be called if your form is valid. It looks like this:

```ruby
def save
  valid? && persist!
end
```

So if you define a `persist!` method on your form like so:

```ruby
def persist!
  MyCommand.persist(to_h)
end
```

Then your controller can stick to the above pattern. You might need the underlying model from that
persistence, so assuming the command above returns that, you can do something like this in your controller

```ruby
# some_controller.rb
if model = @my_object.save
  render json: model.to_json
else
  render json: {errors: model.errors.messages}
end
```

## FAQ

> *What's with the name?*

> **At Influitive we're known for our very creative [portmanteaus](https://en.wikipedia.org/wiki/Portmanteau). This is the ultimate portmanteau of a portmanteau combining Influitive and Form. Clearly we're not very creative people.**

#
> *Will this ever hook into my persistence layer X?*

> **No**

#
> *My association is nil, but my main object still passes validation. How do I prevent this?*

> **Inflorm won't validate nil or empty arrays of associations (since there's nothing to validate). If you need to ensure that the association is there, simply validate its presence like so `validates :child, presence: true`. This will ensure that `child` is not nil (or empty in the `has_many` case)**

## TODO

1. `to_h` right now relies on Rails ActiveSupport `Object#as_json` as it will traverse all properties and convert them recursively to an appropriate primitive or hash/array. This isn't possible right now with just Virtus as calling `to_h` on the Virtus object will still nested associations as their defined instance type. I'm really not happy about having to use Rails monkeypatching for this. Apparently Virtus 2.0 [will have better to_h handling](https://github.com/solnic/virtus/issues/290)
2. The current association validator pollutes the ruby global constant namespace by defining a `AssociatedValidator` class. There's *got* to be a way to register this validation without doing so. This would be a nice change.
3. *Maybe* add `has_one`, `has_many` methods to mimic ActiveRecord associations but for form objects?. I kind of question the extra overhead, although it's not too much cognitive load since most people inherently understand `has_one` / `has_many`

## Credits

I really haven't done any significant work to make this gem. It's all thanks to [virtus contributors](https://github.com/solnic/virtus/graphs/contributors) and [activemodel contributors](https://github.com/rails/rails/tree/master/activemodel). So go thank them!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/inflorm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
