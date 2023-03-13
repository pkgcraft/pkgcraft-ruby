# frozen_string_literal: true

require "ffi"

require_relative "../../_pkgcraft_c"
require_relative "version"

module Pkgcraft
  module Dep
    # CPV object support (category/package-version)
    class Cpv
      include Comparable
      attr_reader :ptr

      def initialize(str)
        ptr = C.pkgcraft_cpv_new(str)
        raise "Invalid Cpv!" if ptr.null?

        self.ptr = ptr
      end

      def self.from_ptr(ptr)
        obj = allocate
        obj.send(:ptr=, ptr)
        obj
      end

      def category
        s, ptr = C.pkgcraft_cpv_category(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def package
        s, ptr = C.pkgcraft_cpv_package(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def version
        Version.from_ptr(C.pkgcraft_cpv_version(@ptr))
      end

      def revision
        version.revision
      end

      def to_s
        s, ptr = C.pkgcraft_cpv_str(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def <=>(other)
        C.pkgcraft_cpv_cmp(@ptr, other.ptr)
      end

      def self.release(ptr)
        C.pkgcraft_cpv_free(ptr)
      end

      private_class_method :release

      private

      def ptr=(ptr)
        @ptr = FFI::AutoPointer.new(ptr, self.class.method(:release))
      end
    end
  end
end
