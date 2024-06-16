# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for Restrict related functionality
  module C
    # Wrapper for Restrict pointers
    class Restrict < AutoPointer
      def self.release(ptr)
        C.pkgcraft_restrict_free(ptr)
      end
    end
  end

  # Restriction related support
  module Restricts
    # Generic restriction.
    class Restrict < C::Restrict
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

      # Try to convert a string to a Restrict pointer.
      def self.from_str(str)
        begin
          return C.pkgcraft_cpv_restrict(Dep::Cpv.new(str))
        rescue Error::InvalidCpv # rubocop:disable Lint/SuppressedException
        end

        begin
          return C.pkgcraft_dep_restrict(Dep::Dep.new(str))
        rescue Error::InvalidDep # rubocop:disable Lint/SuppressedException
        end

        ptr = C.pkgcraft_restrict_parse_dep(str)
        ptr = C.pkgcraft_restrict_parse_pkg(str) if ptr.null?
        raise Error::InvalidRestrict.new("invalid restriction string: #{str}") if ptr.null?

        ptr
      end

      private_class_method :from_str

      def ==(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Restrict

        C.pkgcraft_restrict_eq(self, other)
      end

      alias eql? ==

      def hash
        C.pkgcraft_restrict_hash(self)
      end

      def &(other)
        C.pkgcraft_restrict_and(self, other)
      end

      def |(other)
        C.pkgcraft_restrict_or(self, other)
      end

      def ^(other)
        C.pkgcraft_restrict_xor(self, other)
      end

      def ~
        C.pkgcraft_restrict_not(self)
      end
    end
  end

  # FFI bindings for Restrict related functionality
  module C
    attach_function :pkgcraft_restrict_and, [Restrict, Restrict], Pkgcraft::Restricts::Restrict
    attach_function :pkgcraft_restrict_eq, [Restrict, Restrict], :bool
    attach_function :pkgcraft_restrict_free, [:pointer], :void
    attach_function :pkgcraft_restrict_hash, [Restrict], :uint64
    attach_function :pkgcraft_restrict_not, [Restrict], Pkgcraft::Restricts::Restrict
    attach_function :pkgcraft_restrict_or, [Restrict, Restrict], Pkgcraft::Restricts::Restrict
    attach_function :pkgcraft_restrict_parse_dep, [:string], Restrict
    attach_function :pkgcraft_restrict_parse_pkg, [:string], Restrict
    attach_function :pkgcraft_restrict_xor, [Restrict, Restrict], Pkgcraft::Restricts::Restrict
  end
end
