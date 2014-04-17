module RSpec
  module Expectations
    # Wraps the target of an expectation.
    #
    # @example
    #   expect(something)       # => ExpectationTarget wrapping something
    #   expect { do_something } # => ExpectationTarget wrapping the block
    #
    #   # used with `to`
    #   expect(actual).to eq(3)
    #
    #   # with `not_to`
    #   expect(actual).not_to eq(3)
    #
    # @note `ExpectationTarget` is not intended to be instantiated
    #   directly by users. Use `expect` instead.
    class ExpectationTarget
      # @private
      # Used as a sentinel value to be able to tell when the user
      # did not pass an argument. We can't use `nil` for that because
      # `nil` is a valid value to pass.
      UndefinedValue = Module.new

      # @api private
      def initialize(value, block)
        if UndefinedValue.equal?(value)
          unless @target = block
            raise ArgumentError, "You must pass either an argument or a block to `expect`."
          end
          @block_expectation = true
        elsif block
          raise ArgumentError, "You cannot pass both an argument and a block to `expect`."
        else
          @block_expectation = false
          @target = value
        end
      end

      # Runs the given expectation, passing if `matcher` returns true.
      # @example
      #   expect(value).to eq(5)
      #   expect { perform }.to raise_error
      # @param [Matcher]
      #   matcher
      # @param [String or Proc] message optional message to display when the expectation fails
      # @return [Boolean] true if the expectation succeeds (else raises)
      # @see RSpec::Matchers
      def to(matcher=nil, message=nil, &block)
        enforce_block_matcher(matcher) if @block_expectation
        prevent_operator_matchers(:to) unless matcher
        RSpec::Expectations::PositiveExpectationHandler.handle_matcher(@target, matcher, message, &block)
      end

      # Runs the given expectation, passing if `matcher` returns false.
      # @example
      #   expect(value).not_to eq(5)
      # @param [Matcher]
      #   matcher
      # @param [String or Proc] message optional message to display when the expectation fails
      # @return [Boolean] false if the negative expectation succeeds (else raises)
      # @see RSpec::Matchers
      def not_to(matcher=nil, message=nil, &block)
        enforce_block_matcher(matcher) if @block_expectation
        prevent_operator_matchers(:not_to) unless matcher
        RSpec::Expectations::NegativeExpectationHandler.handle_matcher(@target, matcher, message, &block)
      end
      alias to_not not_to

    private

      def prevent_operator_matchers(verb)
        raise ArgumentError, "The expect syntax does not support operator matchers, " +
                             "so you must pass a matcher to `##{verb}`."
      end

      def enforce_block_matcher(matcher)
        return if block_matcher?(matcher)

        raise ExpectationNotMetError,
          "You must pass an argument rather than a block to use the provided " +
          "matcher (#{description_of matcher}), or the matcher must implement " +
          "`block_matcher?`."
      end

      def block_matcher?(matcher)
        matcher.block_matcher?
      rescue NoMethodError
        false
      end

      def description_of(matcher)
        matcher.description
      rescue NoMethodError
        matcher.inspect
      end
    end
  end
end

