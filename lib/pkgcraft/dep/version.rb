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

    # Package revision
    class Revision < C::Revision
      include InspectPointerRender
      include Comparable

      def initialize(str)
        @ptr = C.pkgcraft_revision_new(str.to_s)
        raise Error::InvalidVersion if @ptr.null?
      end

      def to_s
        C.pkgcraft_revision_str(self)
      end

      def <=>(other)
        C.pkgcraft_revision_cmp(self, other)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_revision_hash(self) if @hash.nil?
        @hash
      end
    end

    # Package version
    class Version < C::Version
      include InspectPointerRender
      include Comparable

      # Create a Version from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.instance_variable_set(:@ptr, ptr)
        obj.instance_variable_set(:@revision, SENTINEL)
        obj
      end

      private_class_method :from_ptr

      def initialize(str)
        @ptr = C.pkgcraft_version_new(str.to_s)
        @revision = SENTINEL
        raise Error::InvalidVersion if @ptr.null?
      end

      def self.valid(str, raised: false)
        valid = !C.pkgcraft_version_valid(str.to_s).null?
        raise Error::InvalidVersion if !valid && raised

        valid
      end

      def op
        op = C.pkgcraft_version_op(self)
        return if op.zero?

        Operator[op]
      end

      def revision
        if @revision.equal?(SENTINEL)
          ptr = C.pkgcraft_version_revision(self)
          @revision = ptr.null? ? nil : ptr
        end
        @revision
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
  end
end
