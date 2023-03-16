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
        val = C.pkgcraft_version_op_from_str(str)
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
    class Version
      include Comparable
      attr_reader :ptr

      def initialize(str)
        ptr = C.pkgcraft_version_new(str.to_s)
        raise Error::InvalidVersion if ptr.null?

        self.ptr = ptr
      end

      def self.from_ptr(ptr)
        return if ptr.null?

        obj = allocate
        obj.send(:ptr=, ptr)
        obj
      end

      def op
        op = C.pkgcraft_version_op(@ptr)
        return if op.zero?

        Operator[op]
      end

      def revision
        s, ptr = C.pkgcraft_version_revision(@ptr)
        return if ptr.null?

        C.pkgcraft_str_free(ptr)
        s
      end

      def intersects(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Version

        C.pkgcraft_version_intersects(@ptr, other.ptr)
      end

      def to_s
        s, ptr = C.pkgcraft_version_str(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def <=>(other)
        C.pkgcraft_version_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @_hash = C.pkgcraft_version_hash(@ptr) if @_hash.nil?

        @_hash
      end

      private

      def ptr=(ptr)
        @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_version_free))
      end
    end

    # Package version with an operator
    class VersionWithOp < Version
      def initialize(str)
        ptr = C.pkgcraft_version_with_op(str.to_s)
        raise Error::InvalidVersion if ptr.null?

        self.ptr = ptr
      end

      def to_s
        s, ptr = C.pkgcraft_version_str_with_op(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end
    end
  end
end
