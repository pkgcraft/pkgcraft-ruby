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

      def to_s
        s, ptr = C.pkgcraft_version_str(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def <=>(other)
        C.pkgcraft_version_cmp(@ptr, other.ptr)
      end

      def self.release(ptr)
        C.pkgcraft_version_free(ptr)
      end

      private_class_method :release

      private

      def ptr=(ptr)
        @ptr = FFI::AutoPointer.new(ptr, self.class.method(:release))
      end
    end
  end
end
