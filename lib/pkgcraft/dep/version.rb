# frozen_string_literal: true

require "ffi"

require_relative "../../_pkgcraft_c"

module Pkgcraft
  module Dep
    # Package version
    class Version
      include Comparable
      attr_reader :ptr

      def initialize(str)
        ptr = C.pkgcraft_version_new(str)
        raise "Invalid Version!" if ptr.null?

        self.ptr = ptr
      end

      def self.from_ptr(ptr)
        obj = allocate
        obj.send(:ptr=, ptr)
        obj
      end

      def revision
        s, ptr = C.pkgcraft_version_revision(@ptr)
        return if ptr.null?

        C.pkgcraft_str_free(ptr)
        s
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
        C.pkgcraft_version_hash(@ptr)
      end

      # :nocov:
      def self.release(ptr)
        C.pkgcraft_version_free(ptr)
      end
      # :nocov:

      private_class_method :release

      private

      def ptr=(ptr)
        @ptr = FFI::AutoPointer.new(ptr, self.class.method(:release))
      end
    end

    # Package version with an operator
    class VersionWithOp < Version
      def initialize(str)
        ptr = C.pkgcraft_version_with_op(str)
        raise "Invalid Version!" if ptr.null?

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
