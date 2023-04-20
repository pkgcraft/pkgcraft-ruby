# frozen_string_literal: true

module Pkgcraft
  module Dep
    # Version operator
    class Operator
      extend FFI::Library

      @enum = enum(
        :Less, 1,
        :LessOrEqual,
        :Equal,
        :EqualGlob,
        :Approximate,
        :GreaterOrEqual,
        :Greater
      )

      def self.[](val)
        val = @enum[val]
        return val unless val.nil?

        raise "unknown value: #{val}"
      end

      def self.from_str(str)
        val = C.pkgcraft_version_op_from_str(str.to_s)
        return @enum[val] unless val.zero?

        raise "unknown value: #{val}"
      end

      def self.const_missing(symbol)
        # look up symbol as an enum
        value = enum_value(symbol)

        # if nonexistent, raise an exception via the default behavior
        return super unless value

        @enum[value]
      end
    end

    # Package version
    class Version < C::Version
      include InspectPointerRender
      include Comparable

      def initialize(str)
        @ptr = C.pkgcraft_version_new(str.to_s)
        raise Error::InvalidVersion if @ptr.null?
      end

      def op
        op = C.pkgcraft_version_op(self)
        return if op.zero?

        Operator[op]
      end

      def revision
        C.pkgcraft_version_revision(self)
      end

      def intersects(other)
        C.pkgcraft_version_intersects(self, other)
      end

      def to_s
        C.pkgcraft_version_str(self)
      end

      def <=>(other)
        C.pkgcraft_version_cmp(self, other)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_version_hash(self) if @hash.nil?
        @hash
      end
    end

    # Package version with an operator
    class VersionWithOp < Version
      def initialize(str)
        @ptr = C.pkgcraft_version_with_op(str.to_s)
        raise Error::InvalidVersion if @ptr.null?
      end

      def to_s
        C.pkgcraft_version_str_with_op(self)
      end
    end
  end
end
