# cfncli
[![Gem Version](https://badge.fury.io/rb/cfncli.svg)](https://badge.fury.io/rb/cfncli)
[![Build Status](https://travis-ci.org/lethalpaga/cfncli.svg?branch=master)](https://travis-ci.org/lethalpaga/cfncli)
[![Code Climate](https://codeclimate.com/github/lethalpaga/cfncli/badges/gpa.svg)](https://codeclimate.com/github/lethalpaga/cfncli)
[![Test Coverage](https://codeclimate.com/github/lethalpaga/cfncli/badges/coverage.svg)](https://codeclimate.com/github/lethalpaga/cfncli/coverage)

cfncli is a command line tool that simplifies the creation of Cloudformation stacks.
It's designed to be a very simple wrapper around the Cloudformation API, but adds the following features compared to
the AWS cli :
 * Can wait for the stack creation/update/deletion to be complete before returning
 * Prints the stack events on the console
 * Gives back a return code indicating if the operation was a success or failure

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cfncli'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cfncli

## Usage

```
cfncli help
cfncli help apply
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lethalpaga/cfncli.

