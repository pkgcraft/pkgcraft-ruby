# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for DepSpec related functionality
  module C
    # DepSpec wrapper
    class DepSpec < FFI::ManagedStruct
      layout :set, :int,
             :kind, :int,
             :ptr,  :pointer

      def self.release(ptr)
        C.pkgcraft_dep_spec_free(ptr)
      end
    end

    typedef DepSpec.by_ref, :DepSpec
    attach_function :pkgcraft_dep_spec_cmp, [:DepSpec, :DepSpec], :int
    attach_function :pkgcraft_dep_spec_hash, [:DepSpec], :uint64
    attach_function :pkgcraft_dep_spec_str, [:DepSpec], String
    attach_function :pkgcraft_dep_spec_free, [:pointer], :void
    attach_function :pkgcraft_dep_spec_into_iter_flatten, [:DepSpec], :pointer
    attach_function :pkgcraft_dep_spec_into_iter_recursive, [:DepSpec], :pointer
  end

  module Dep
    # Set of dependency objects.
    class DepSpec
      include InspectStruct
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

      def iter_flatten
        IterFlatten.new(self)
      end

      def iter_recursive
        IterRecursive.new(self)
      end

      def <=>(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? DepSpec

        C.pkgcraft_dep_spec_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_dep_spec_hash(@ptr) if @hash.nil?
        @hash
      end

      def to_s
        C.pkgcraft_dep_spec_str(@ptr)
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
