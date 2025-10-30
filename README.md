# Ratchet

## Initial Implementation Plan

Looking back at years of building and using [packwerk](https://github.com/Shopify/packwerk), there are some major things I would like to improve in the next version.

Properties I want from ratchet:

- extract the most complex, least specific part into a reusable module. That is, finding all external references from a Ruby file
- enabled by the above, allow arbitrary (through extension) rules to be expressed over that foundational reference graph
  - start with layering, the most common architecture rule (_A boundary in software architecture is a line that is crossed by dependencies only in one direction_)
- optionally and later, future-proof the core
  - make sure it uses a current version of prism in the canonical way for parsing
  - remove the dependency on zeitwerk _or_ go all in on zeitwerk and remove constant_resolver

There is a possible version of this where ratchet-core is a separate gem.

Also, please note that all names are temporary at this point.

I am not pushing this as a next version of packwerk though due to two reasons:

- Packwerk development has been at a snail's pace for the last few years as Shopify has reduced its ongoing investment to just "keeping the lights on" and I don't have the influence required to change that - I don't want to spend energy arguing, I want to push this out into the world
- Packwerk's original architecture was based on assumptions that have long been invalidated (e.g. running as a rubocop cop) and it's difficult to remove the remnants of these decisions from its architecture
- Packwerk has accumulated a lot of complexity to enable less common use cases and add convenience. Those would slow down iteration towards a different paradigm.

Relevant open PRs on packwerk:

- [packwerk#410](https://github.com/Shopify/packwerk/pull/410) Proof of concept for removing ConstantResolver and using Zeitwerk for ConstantDiscovery
- [packwerk#397](https://github.com/Shopify/packwerk/pull/397) Allow fetching all references for a file, or all files, using public API

## Default Gem README

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/ratchet`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/exterm/ratchet. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/exterm/ratchet/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ratchet project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/exterm/ratchet/blob/main/CODE_OF_CONDUCT.md).
