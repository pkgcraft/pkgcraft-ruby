# frozen_string_literal: true

module Pkgcraft
  module Dep
    # Cpn object support (category/package)
    class Cpn < C::Cpn
      include InspectPointerRender
      include Comparable

      # Create a Cpn from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.instance_variable_set(:@ptr, ptr)
        obj
      end

      private_class_method :from_ptr

      def initialize(str)
        @ptr = C.pkgcraft_cpn_new(str.to_s)
        raise Error::InvalidCpn if @ptr.null?
      end

      def category
        @category = C.pkgcraft_cpn_category(self) if @category.nil?
        @category
      end

      def package
        @package = C.pkgcraft_cpn_package(self) if @package.nil?
        @package
      end

      def to_s
        C.pkgcraft_cpn_str(self)
      end

      def <=>(other)
        C.pkgcraft_cpn_cmp(self, other)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_cpn_hash(self) if @hash.nil?
        @hash
      end
    end
  end

  # FFI bindings for Cpn related functionality
  module C
    attach_function :pkgcraft_cpn_category, [Cpn], String
    attach_function :pkgcraft_cpn_cmp, [Cpn, Cpn], :int
    attach_function :pkgcraft_cpn_free, [:pointer], :void
    attach_function :pkgcraft_cpn_hash, [Cpn], :uint64
    attach_function :pkgcraft_cpn_new, [:string], Cpn
    attach_function :pkgcraft_cpn_package, [Cpn], String
    attach_function :pkgcraft_cpn_str, [Cpn], String
  end
end
