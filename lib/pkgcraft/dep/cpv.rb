# frozen_string_literal: true

require "ffi"

require_relative "../../pkgcraft_c"

module Pkgcraft
  module Dep
    # CPV object support (category/package-version)
    class Cpv
      def initialize(str)
        ptr = C.pkgcraft_cpv_new(str)
        raise "Invalid Cpv!" if ptr.null?

        @ptr = FFI::AutoPointer.new(ptr, self.class.method(:release))
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

      def self.release(ptr)
        C.pkgcraft_cpv_free(ptr)
      end

      private_class_method :release
    end
  end
end
