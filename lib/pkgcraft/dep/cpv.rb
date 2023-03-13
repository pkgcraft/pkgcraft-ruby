# frozen_string_literal: true

require "ffi"

require_relative "../../pkgcraft_c"
require_relative "version"

module Pkgcraft
  module Dep
    # CPV object support (category/package-version)
    class Cpv
      attr_reader :ptr

      def initialize(str)
        ptr = C.pkgcraft_cpv_new(str)
        raise "Invalid Cpv!" if ptr.null?

        @ptr = FFI::AutoPointer.new(ptr, self.class.method(:release))
      end

      def category
        s, ptr = C.pkgcraft_cpv_category(self.ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def package
        s, ptr = C.pkgcraft_cpv_package(self.ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def version
        ptr = C.pkgcraft_cpv_version(self.ptr)
        Version.from_ptr(ptr)
      end

      def self.release(ptr)
        C.pkgcraft_cpv_free(ptr)
      end

      private_class_method :release
    end
  end
end
