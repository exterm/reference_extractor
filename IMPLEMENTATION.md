# ReferenceExtractor Implementation Notes

## Initial Implementation Plan

Looking back at years of building and using [packwerk](https://github.com/Shopify/packwerk), there are some major things I would like to improve in the next version.

Properties I want from ReferenceExtractor:

- extract the most complex, least specific part into a reusable module. That is, finding all external references from a Ruby file
- enabled by the above, allow arbitrary (through extension) rules to be expressed over that foundational reference graph
  - start with layering, the most common architecture rule (_A boundary in software architecture is a line that is crossed by dependencies only in one direction_)
- optionally and later, future-proof the core
  - make sure it uses a current version of prism in the canonical way for parsing
  - remove the dependency on zeitwerk _or_ go all in on zeitwerk and remove constant_resolver

There is a possible version of this where reference_extractor-core is a separate gem.

Also, please note that all names are temporary at this point.

I am not pushing this as a next version of packwerk though due to two reasons:

- Packwerk development has been at a snail's pace for the last few years as Shopify has reduced its ongoing investment to just "keeping the lights on" and I don't have the influence required to change that - I don't want to spend energy arguing, I want to push this out into the world
- Packwerk's original architecture was based on assumptions that have long been invalidated (e.g. running as a rubocop cop) and it's difficult to remove the remnants of these decisions from its architecture
  - another outdated assumption is that config validation is slow while the actual reference checking is fast. Nowadays both require bootup of the application, so there is actually no need for a separate `validate` command
- Packwerk has accumulated a lot of complexity to enable less common use cases and add convenience. Those would slow down iteration towards a different paradigm.

Relevant open PRs on packwerk:

- [packwerk#410](https://github.com/Shopify/packwerk/pull/410) Proof of concept for removing ConstantResolver and using Zeitwerk for ConstantDiscovery
- [packwerk#397](https://github.com/Shopify/packwerk/pull/397) Allow fetching all references for a file, or all files, using public API

## Implemented Improvements over Packwerk

- Removed dependency on `constant_resolver` by depending directly on zeitwerk for reverse lookup, thanks to @Catsuko ([packwerk#410](https://github.com/Shopify/packwerk/pull/410))
- Replaced `better_html` with `herb` which comes with a lot less dependencies
- remove possibly outdated encoding handling from parsers
- fixed prism deprecation warnings, thanks to @Earlopain ([packwerk#431](https://github.com/Shopify/packwerk/pull/431))

## TO DO

- add association inspector from Packwerk
- rename the whole thing to ReferenceExtractor / reference_extractor
- investigate "don't report reference to same file" fix. Shouldn't ParsedConstantDefinitions handle that?

## Ideas

- Shortcuts
  - for CLI command, use a CLI library instead of hand-rolling it
    - probably, `optparse` built into the stdlib
- Name
  - Lattice, keeps your ruby in shape
  - Streckennetzplan, a roadmap for your rails architecture
- Eliminate Rails dependency
  - would be nice to just depend on zeitwerk, not Rails
  - instead of reading from `Rails.autoloaders`, can we just get the autoloaders from Zeitwerk?
- cleanups
  - pass filenames and paths around as Pathname objects, not strings
  - introduce an Internal namespace
