# Inflorm

Simple Form Objects with validations and associations

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'inflorm'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install inflorm

## Usage

Inflorm is nothing more than a thin wrapper over [Virtus](https://github.com/solnic/virtus)
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
  p.valid? # => true

  # Object with has_many association
  p = Parent.new pets: [{species: 'dog', name: 'George'}, {species: 'cat', name: 'Fluffy'}]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/inflorm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
