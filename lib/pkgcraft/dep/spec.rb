# frozen_string_literal: true

module Pkgcraft
  module Dep
    # Set of dependency objects.
    class DepSpec
      attr_reader :ptr

      # Create a DepSpec from a pointer.
      def self.from_ptr(ptr)
        case ptr[:kind]
        when 0
          obj = Enabled.allocate
        when 1
          obj = Disabled.allocate
        when 2
          obj = AllOf.allocate
        when 3
          obj = AnyOf.allocate
        when 4
          obj = ExactlyOneOf.allocate
        when 5
          obj = AtMostOneOf.allocate
        when 6
          obj = UseEnabled.allocate
        when 7
          obj = UseDisabled.allocate
        else
          "unsupported DepSpec kind: #{ptr[:kind]}"
        end

        obj.instance_variable_set(:@ptr, ptr)
        obj
      end

      private_class_method :from_ptr

      def <=>(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? DepSpec

        C.pkgcraft_dep_spec_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @_hash = C.pkgcraft_dep_spec_hash(@ptr) if @_hash.nil?
        @_hash
      end

      def to_s
        s, c_str = C.pkgcraft_dep_spec_str(@ptr)
        C.pkgcraft_str_free(c_str)
        s
      end
    end

    class Enabled < DepSpec; end
    class Disabled < DepSpec; end
    class AllOf < DepSpec; end
    class AnyOf < DepSpec; end
    class ExactlyOneOf < DepSpec; end
    class AtMostOneOf < DepSpec; end
    class UseDisabled < DepSpec; end
    class UseEnabled < DepSpec; end
  end
end
