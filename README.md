# 🚧 [WIP] ReferenceExtractor [WIP] 🚧

## Introduction

ReferenceExtractor parses Ruby files and returns the constants they reference, using your Zeitwerk autoloaders to resolve what lives where. It gives you a graph you can use for architecture rules like layering or dependency checks.

ReferenceExtractor is in _prototype_ stage. It works in general but is not battle tested.

It is based on [packwerk](https://github.com/Shopify/packwerk).

## Usage

```ruby
extractor = ReferenceExtractor::Extractor.new(
  autoloaders: Rails.autoloaders,
  root_path: Rails.root
)

# From a string snippet
extractor.references_from_string("Order.find(1)")
# => [#<ReferenceExtractor::Reference constant=#<ReferenceExtractor::ConstantContext name=\"::Order\" ...>>]

# From a file relative to root_path
extractor.references_from_file("app/models/user.rb")
# => [#<ReferenceExtractor::Reference ...>, ...]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Publishing to RubyGems

1. Update the version in `lib/reference_extractor/version.rb`. Push / merge to main.
2. Build the gem:

   ```bash
   gem build reference_extractor.gemspec
   ```

   This should produce `reference_extractor-<version>.gem`.
3. Sign in to RubyGems (only needed once):

   ```bash
   gem signin
   ```

4. Push the built gem:

   ```bash
   gem push reference_extractor-<version>.gem
   ```

5. Tag the release:

   ```bash
   git tag v<version> && git push origin v<version>
   ```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/exterm/reference_extractor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/exterm/reference_extractor/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ReferenceExtractor project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/exterm/reference_extractor/blob/main/CODE_OF_CONDUCT.md).
