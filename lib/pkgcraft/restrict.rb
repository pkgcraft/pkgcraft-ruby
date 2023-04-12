# frozen_string_literal: true

module Pkgcraft
  # Error support
  module Restrict
    # Generic restriction.
    class Restrict
      include Dep
      include Error
      attr_reader :ptr

      def initialize(obj)
        self.ptr = Restrict.send(:from_obj, obj)
      end

      # Create a Restrict from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.send(:ptr=, ptr)
        obj
      end

      private_class_method :from_ptr

      # Try to convert an object to a Restrict pointer.
      def self.from_obj(obj)
        case obj
        when Cpv
          C.pkgcraft_cpv_restrict(obj.ptr)
        when Dep
          C.pkgcraft_dep_restrict(obj.ptr)
        when Pkg
          C.pkgcraft_pkg_restrict(obj.ptr)
        when String
          Restrict.send(:from_str, obj)
        else
          raise TypeError.new("unsupported restrict type: #{obj.class}")
        end
      end

      private_class_method :from_obj

      # Try to convert a string to a Restrict pointer.
      def self.from_str(str)
        begin
          return C.pkgcraft_cpv_restrict(Cpv.new(str).ptr)
        rescue InvalidCpv # rubocop:disable Lint/SuppressedException
        end

        begin
          return C.pkgcraft_dep_restrict(Dep.new(str).ptr)
        rescue InvalidDep # rubocop:disable Lint/SuppressedException
        end

        r = C.pkgcraft_restrict_parse_dep(str)
        r = C.pkgcraft_restrict_parse_pkg(str) if r.nil?
        raise InvalidRestrict.new("invalid restriction string: #{str}") if r.nil?

        r
      end

      private_class_method :from_str

      def ptr=(ptr)
        @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_restrict_free))
      end
    end
  end
end
