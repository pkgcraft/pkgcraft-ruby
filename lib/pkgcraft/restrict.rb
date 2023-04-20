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
          @ptr = C.pkgcraft_cpv_restrict(obj)
        when Dep::Dep
          @ptr = C.pkgcraft_dep_restrict(obj)
        when Pkgs::Pkg
          @ptr = C.pkgcraft_pkg_restrict(obj)
        when String
          @ptr = Restrict.send(:from_str, obj)
        else
          raise TypeError.new("unsupported restrict type: #{obj.class}")
        end
      end

      # Create a Restrict from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        obj.instance_variable_set(:@ptr, ptr)
        obj
      end

      private_class_method :from_ptr

      # Try to convert a string to a Restrict pointer.
      def self.from_str(str)
        begin
          return C.pkgcraft_cpv_restrict(Dep::Cpv.new(str))
        rescue InvalidCpv # rubocop:disable Lint/SuppressedException
        end

        begin
          return C.pkgcraft_dep_restrict(Dep::Dep.new(str))
        rescue InvalidDep # rubocop:disable Lint/SuppressedException
        end

        ptr = C.pkgcraft_restrict_parse_dep(str)
        ptr = C.pkgcraft_restrict_parse_pkg(str) if ptr.null?
        raise InvalidRestrict.new("invalid restriction string: #{str}") if ptr.null?

        ptr
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
    end
  end
end
