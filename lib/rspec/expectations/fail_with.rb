RSpec::Support.require_rspec_support 'differ'

module RSpec
  module Expectations
    class << self
      # @private
      def differ
        RSpec::Support::Differ.new(
          :object_preparer => lambda { |object| RSpec::Matchers::Composable.surface_descriptions_in(object) },
          :color => RSpec::Matchers.configuration.color?
        )
      end

      # Raises an RSpec::Expectations::ExpectationNotMetError with message.
      # @param [String] message
      # @param [Object] expected
      # @param [Object] actual
      # @param [String] diff
      #
      # Adds a diff to the failure message when `expected` and `actual` are
      # both present.
      def fail_with(message, expected=nil, actual=nil, diff=nil)
        unless message
          raise ArgumentError, "Failure message is nil. Does your matcher define the " \
                               "appropriate failure_message[_when_negated] method to return a string?"
        end

        diff ||= differ.diff(actual, expected)
        message = "#{message}\nDiff:#{diff}" unless diff.empty?

        raise RSpec::Expectations::ExpectationNotMetError, message
      end

      def compound_fail_with(matcher, message, actual)
        fail_with(message, nil, nil, compound_diff(matcher, actual))
      end

      def compound_diff(matcher, actual)
        if ::RSpec::Matchers::BuiltIn::Compound::And === matcher
          diff_for_and_matcher(matcher, actual)
        elsif ::RSpec::Matchers::BuiltIn::Compound::Or === matcher
          diff_for_or_matcher(matcher, actual)
        else
          differ.diff(actual, matcher.expected)
        end
      end

      def diff_for_and_matcher(matcher, actual)
        diff1 = compound_diff(matcher.matcher_1, actual)
        diff2 = compound_diff(matcher.matcher_2, actual)
        if matcher.matcher_1_matches?
          diff2
        elsif matcher.matcher_2_matches?
          diff1
        else
          "#{diff1}\n#{diff2}"
        end
      end

      def diff_for_or_matcher(matcher, actual)
        diff1 = compound_diff(matcher.matcher_1, actual)
        diff2 = compound_diff(matcher.matcher_2, actual)
        "#{diff1}\n#{diff2}"
      end
    end
  end
end
