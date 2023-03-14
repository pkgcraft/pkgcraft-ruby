# frozen_string_literal: true

module Pkgcraft
  module Dep
    # Package dependency
    class Dep
      include Comparable
      attr_reader :ptr

      def initialize(str)
        ptr = C.pkgcraft_dep_new(str, nil)
        raise "Invalid dep: #{str}" if ptr.null?

        self.ptr = ptr
      end

      def self.from_ptr(ptr)
        obj = allocate
        obj.send(:ptr=, ptr)
        obj
      end

      def category
        s, ptr = C.pkgcraft_dep_category(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def package
        s, ptr = C.pkgcraft_dep_package(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def version
        Version.from_ptr(C.pkgcraft_dep_version(@ptr))
      end

      def revision
        version.revision
      end

      def intersects(other)
        return C.pkgcraft_dep_intersects(@ptr, other.ptr) if other.is_a? Dep

        return C.pkgcraft_dep_intersects_cpv(@ptr, other.ptr) if other.is_a? Cpv

        raise "Invalid type: #{other.class}"
      end

      def to_s
        s, ptr = C.pkgcraft_dep_str(@ptr)
        C.pkgcraft_str_free(ptr)
        s
      end

      def <=>(other)
        C.pkgcraft_dep_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @_hash = C.pkgcraft_dep_hash(@ptr) if @_hash.nil?

        @_hash
      end

      # :nocov:
      def self.release(ptr)
        C.pkgcraft_dep_free(ptr)
      end
      # :nocov:

      private_class_method :release

      private

      def ptr=(ptr)
        @ptr = FFI::AutoPointer.new(ptr, self.class.method(:release))
      end
    end
  end
end
