require 'yaml'

require 'axe/cucumber'
require 'axe/matchers/be_accessible'

# The purpose of this class is to enable private helper methods for assertion
# and cucumber argument parsing without leaking the helper methods into the
# cucumber World object.
# Further, using these helper methods for assert/refute removes the dependency
# on rspec. So end users may choose to use any (or non) assertion/expectation
# library, as this class uses the Axe Accessibility Matcher directly, without
# using a matcher/expectation library DSL.
module Axe
  module Cucumber
    class Step
      REGEX = /^the page should(?<negate> not)? be accessible(?: within "(?<inclusion>.*?)")?(?:(?: but)? excluding "(?<exclusion>.*?)")?(?: according to: (?<tags>.*?))?(?: checking(?<run_only> only)?: (?<run_rules>.*?))?(?: skipping: (?<skip_rules>.*?))?(?: with options: (?<options>.*?))?$/

      def self.create_for(world)
        new Axe::Cucumber.page_from world
      end

      def initialize(page)
        @page = page
      end

      def be_accessible(negate, inclusion, exclusion, tags, run_only, run_rules, skip_rules, options)
        accessibility = Matchers::BeAccessible.new

        accessibility.within(selector inclusion) if inclusion
        accessibility.excluding(selector exclusion) if exclusion
        accessibility.according_to(split tags) if tags
        run_only ? accessibility.checking_only(split run_rules) : accessibility.checking(split run_rules) if run_rules
        accessibility.skipping(split skip_rules) if skip_rules
        accessibility.with_options(to_hash options) if options

        if negate then refute accessibility else assert accessibility end
      end

      private

      attr_reader :page

      def selector(selector)
        split(selector)
      end

      def split(string)
        string.to_s.split(/,\s*/)
      end

      def to_hash(string)
        YAML.load string
      end

      def assert(matcher)
        raise matcher.failure_message unless matcher.matches? page
      end

      def refute(matcher)
        raise matcher.failure_message_when_negated if matcher.matches? page
      end
    end
  end
end
