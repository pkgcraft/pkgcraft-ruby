# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for DependencySet related functionality
  module C
    # Dependency wrapper
    class Dependency < FFI::ManagedStruct
      layout :set, :int,
             :kind, :int,
             :ptr,  :pointer

      def self.release(ptr)
        C.pkgcraft_dependency_free(ptr)
      end
    end

    # Wrapper for DependencySet objects.
    class DependencySet < FFI::ManagedStruct
      layout :set, :int,
             :ptr, :pointer

      def self.release(ptr)
        C.pkgcraft_dependency_set_free(ptr)
      end
    end

    # Wrapper for Uri pointers.
    class Uri < AutoPointer
      def self.release(ptr)
        C.pkgcraft_uri_free(ptr)
      end
    end

    # Dependency support
    typedef Dependency.by_ref, :Dependency
    attach_function :pkgcraft_dependency_cmp, [:Dependency, :Dependency], :int
    attach_function :pkgcraft_dependency_hash, [:Dependency], :uint64
    attach_function :pkgcraft_dependency_str, [:Dependency], String
    attach_function :pkgcraft_dependency_parse, [:string, Eapi, :int], :Dependency
    attach_function :pkgcraft_dependency_free, [:pointer], :void
    attach_function :pkgcraft_dependency_into_iter_flatten, [:Dependency], :pointer
    attach_function :pkgcraft_dependency_into_iter_recursive, [:Dependency], :pointer

    # DependencySet support
    typedef DependencySet.by_ref, :DependencySet
    attach_function :pkgcraft_dependency_set_eq, [:DependencySet, :DependencySet], :bool
    attach_function :pkgcraft_dependency_set_hash, [:DependencySet], :uint64
    attach_function :pkgcraft_dependency_set_str, [:DependencySet], String
    attach_function :pkgcraft_dependency_set_len, [:DependencySet], :uint64
    attach_function :pkgcraft_dependency_set_is_empty, [:DependencySet], :bool
    attach_function :pkgcraft_dependency_set_parse, [:string, Eapi, :int], :DependencySet
    attach_function :pkgcraft_dependency_set_free, [:pointer], :void
    attach_function :pkgcraft_dependency_set_into_iter, [:DependencySet], :pointer
    attach_function :pkgcraft_dependency_set_into_iter_next, [:pointer], :Dependency
    attach_function :pkgcraft_dependency_set_into_iter_free, [:pointer], :void
    attach_function :pkgcraft_dependency_set_into_iter_flatten, [:DependencySet], :pointer
    attach_function :pkgcraft_dependency_set_into_iter_flatten_next, [:pointer], :pointer
    attach_function :pkgcraft_dependency_set_into_iter_flatten_free, [:pointer], :void
    attach_function :pkgcraft_dependency_set_into_iter_recursive, [:DependencySet], :pointer
    attach_function :pkgcraft_dependency_set_into_iter_recursive_next, [:pointer], :Dependency
    attach_function :pkgcraft_dependency_set_into_iter_recursive_free, [:pointer], :void

    # Uri support
    attach_function :pkgcraft_uri_filename, [Uri], String
    attach_function :pkgcraft_uri_str, [Uri], String
    attach_function :pkgcraft_uri_uri, [Uri], String
    attach_function :pkgcraft_uri_free, [:pointer], :void
  end

  module Dep
    # Dependency objects.
    class Dependency
      include InspectStruct
      attr_reader :ptr

      # Create a Dependency from a pointer.
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
          "unsupported Dependency kind: #{ptr[:kind]}"
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
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? Dependency

        C.pkgcraft_dependency_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_dependency_hash(@ptr) if @hash.nil?
        @hash
      end

      def to_s
        C.pkgcraft_dependency_str(@ptr)
      end
    end

    class Enabled < Dependency; end
    class Disabled < Dependency; end
    class AllOf < Dependency; end
    class AnyOf < Dependency; end
    class ExactlyOneOf < Dependency; end
    class AtMostOneOf < Dependency; end
    class UseDisabled < Dependency; end
    class UseEnabled < Dependency; end

    # Set of dependency objects.
    class DependencySet
      include Pkgcraft::Eapis
      include InspectStruct
      include Enumerable
      attr_reader :ptr

      # Create a DependencySet from a pointer.
      def self.from_ptr(ptr, obj = nil)
        if obj.nil?
          case ptr[:set]
          when 0
            obj = Package.allocate
          when 1
            obj = SrcUri.allocate
          when 2
            obj = License.allocate
          when 3
            obj = Properties.allocate
          when 4
            obj = RequiredUse.allocate
          when 5
            obj = Restrict.allocate
          else
            "unsupported DependencySet kind: #{ptr[:set]}"
          end
        end
        obj.instance_variable_set(:@ptr, ptr)
        obj
      end

      private_class_method :from_ptr

      def initialize(str = nil, eapi = EAPI_LATEST)
        eapi = Eapi.from_obj(eapi)
        if is_a? Package
          kind = 0
        elsif is_a? SrcUri
          kind = 1
        elsif is_a? License
          kind = 2
        elsif is_a? Properties
          kind = 3
        elsif is_a? RequiredUse
          kind = 4
        elsif is_a? Restrict
          kind = 5
        else
          "unsupported DependencySet kind: #{ptr[:set]}"
        end
        ptr = C.pkgcraft_dependency_set_parse(str.to_s, eapi, kind)
        raise Error::PkgcraftError if ptr.null?

        DependencySet.send(:from_ptr, ptr, self)
      end

      # Iterator over a DependencySet.
      class Iter
        include Enumerable

        def initialize(ptr)
          iter_p = C.pkgcraft_dependency_set_into_iter(ptr)
          @ptr = FFI::AutoPointer.new(iter_p, C.method(:pkgcraft_dependency_set_into_iter_free))
        end

        def each
          loop do
            ptr = C.pkgcraft_dependency_set_into_iter_next(@ptr)
            break if ptr.null?

            yield Dependency.send(:from_ptr, ptr)
          end
        end
      end

      private_constant :Iter

      def iter
        Iter.new(@ptr)
      end

      def each(&)
        iter.each(&)
      end

      def iter_flatten
        IterFlatten.new(self)
      end

      def iter_recursive
        IterRecursive.new(self)
      end

      def ==(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? DependencySet

        C.pkgcraft_dependency_set_eq(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_dependency_set_hash(@ptr) if @hash.nil?
        @hash
      end

      def length
        C.pkgcraft_dependency_set_len(@ptr)
      end

      def empty?
        C.pkgcraft_dependency_set_is_empty(@ptr)
      end

      def to_s
        C.pkgcraft_dependency_set_str(@ptr)
      end
    end

    # Flattened iterator over a DependencySet or Dependency.
    class IterFlatten
      include Enumerable

      def initialize(obj)
        case obj
        when DependencySet
          iter_p = C.pkgcraft_dependency_set_into_iter_flatten(obj.ptr)
        when Dependency
          iter_p = C.pkgcraft_dependency_into_iter_flatten(obj.ptr)
        else
          raise TypeError.new("unsupported dep type: #{obj.class}")
        end

        @ptr = FFI::AutoPointer.new(
          iter_p, C.method(:pkgcraft_dependency_set_into_iter_flatten_free)
        )
        @set = obj.ptr[:set]
      end

      def each
        loop do
          ptr = C.pkgcraft_dependency_set_into_iter_flatten_next(@ptr)
          break if ptr.null?

          case @set
          when 0
            yield Dep.from_native(ptr)
          when 1
            yield Uri.from_native(ptr)
          else
            s = ptr.read_string
            C.pkgcraft_str_free(ptr)
            yield s
          end
        end
      end
    end

    private_constant :IterFlatten

    # Recursive iterator over a DependencySet or Dependency.
    class IterRecursive
      include Enumerable

      def initialize(obj)
        case obj
        when DependencySet
          iter_p = C.pkgcraft_dependency_set_into_iter_recursive(obj.ptr)
        when Dependency
          iter_p = C.pkgcraft_dependency_into_iter_recursive(obj.ptr)
        else
          raise TypeError.new("unsupported dep type: #{obj.class}")
        end

        @ptr = FFI::AutoPointer.new(
          iter_p, C.method(:pkgcraft_dependency_set_into_iter_recursive_free)
        )
        @set = obj.ptr[:set]
      end

      def each
        loop do
          ptr = C.pkgcraft_dependency_set_into_iter_recursive_next(@ptr)
          break if ptr.null?

          yield Dependency.send(:from_ptr, ptr)
        end
      end
    end

    private_constant :IterRecursive

    class Package < DependencySet; end
    class License < DependencySet; end
    class Properties < DependencySet; end
    class RequiredUse < DependencySet; end
    class Restrict < DependencySet; end
    class SrcUri < DependencySet; end

    # URI objects for the SRC_URI DependencySet.
    class Uri < C::Uri
      def uri
        C.pkgcraft_uri_uri(self)
      end

      def filename
        C.pkgcraft_uri_filename(self)
      end

      def to_s
        C.pkgcraft_uri_str(self)
      end
    end

    private_constant :Uri
  end
end
