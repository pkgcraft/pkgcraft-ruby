# frozen_string_literal: true

module Pkgcraft
  # Error support
  module Restricts
    # Generic restriction.
    class Restrict
      include Error
      attr_reader :ptr

      def initialize(obj)
        case obj
        when Dep::Cpv
          self.ptr = C.pkgcraft_cpv_restrict(obj.ptr)
        when Dep::Dep
          self.ptr = C.pkgcraft_dep_restrict(obj.ptr)
        when Pkg::Pkg
          self.ptr = C.pkgcraft_pkg_restrict(obj.ptr)
        when String
          self.ptr = Restrict.send(:from_str, obj)
        else
          raise TypeError.new("unsupported restrict type: #{obj.class}")
        end
      end

      # Create a Restrict from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.send(:ptr=, ptr)
        obj
      end

      private_class_method :from_ptr

      # Try to convert a string to a Restrict pointer.
      def self.from_str(str)
        begin
          return C.pkgcraft_cpv_restrict(Dep::Cpv.new(str).ptr)
        rescue InvalidCpv # rubocop:disable Lint/SuppressedException
        end

        begin
          return C.pkgcraft_dep_restrict(Dep::Dep.new(str).ptr)
        rescue InvalidDep # rubocop:disable Lint/SuppressedException
        end

        r = C.pkgcraft_restrict_parse_dep(str)
        r = C.pkgcraft_restrict_parse_pkg(str) if r.nil?
        raise InvalidRestrict.new("invalid restriction string: #{str}") if r.nil?

        r
      end

      private_class_method :from_str

      def ==(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Restrict

        C.pkgcraft_restrict_eq(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        C.pkgcraft_restrict_hash(@ptr)
      end

      def &(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Restrict

        Restrict.send(:from_ptr, C.pkgcraft_restrict_and(@ptr, other.ptr))
      end

      def |(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Restrict

        Restrict.send(:from_ptr, C.pkgcraft_restrict_or(@ptr, other.ptr))
      end

      def ^(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Restrict

        Restrict.send(:from_ptr, C.pkgcraft_restrict_xor(@ptr, other.ptr))
      end

      def ~
        Restrict.send(:from_ptr, C.pkgcraft_restrict_not(@ptr))
      end

      def ptr=(ptr)
        @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_restrict_free))
      end
    end
  end
end
