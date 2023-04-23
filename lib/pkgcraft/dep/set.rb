# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for DepSet related functionality
  module C
    # Wrapper for DepSet objects.
    class DepSet < FFI::ManagedStruct
      layout :unit, :int,
             :kind, :int,
             :ptr,  :pointer

      def self.release(ptr)
        C.pkgcraft_dep_set_free(ptr)
      end
    end

    # Wrapper for Uri pointers.
    class Uri < AutoPointer
      def self.release(ptr)
        C.pkgcraft_uri_free(ptr)
      end
    end

    # DepSet support
    typedef DepSet.by_ref, :DepSet
    attach_function :pkgcraft_dep_set_eq, [:DepSet, :DepSet], :bool
    attach_function :pkgcraft_dep_set_hash, [:DepSet], :uint64
    attach_function :pkgcraft_dep_set_str, [:DepSet], String
    attach_function :pkgcraft_dep_set_dependencies, [:string, Eapi], :DepSet
    attach_function :pkgcraft_dep_set_license, [:string], :DepSet
    attach_function :pkgcraft_dep_set_properties, [:string], :DepSet
    attach_function :pkgcraft_dep_set_required_use, [:string, Eapi], :DepSet
    attach_function :pkgcraft_dep_set_restrict, [:string], :DepSet
    attach_function :pkgcraft_dep_set_src_uri, [:string, Eapi], :DepSet
    attach_function :pkgcraft_dep_set_free, [:pointer], :void
    attach_function :pkgcraft_dep_set_into_iter, [:DepSet], :pointer
    attach_function :pkgcraft_dep_set_into_iter_next, [:pointer], :DepSpec
    attach_function :pkgcraft_dep_set_into_iter_free, [:pointer], :void
    attach_function :pkgcraft_dep_set_into_iter_flatten, [:DepSet], :pointer
    attach_function :pkgcraft_dep_set_into_iter_flatten_next, [:pointer], :pointer
    attach_function :pkgcraft_dep_set_into_iter_flatten_free, [:pointer], :void
    attach_function :pkgcraft_dep_set_into_iter_recursive, [:DepSet], :pointer
    attach_function :pkgcraft_dep_set_into_iter_recursive_next, [:pointer], :DepSpec
    attach_function :pkgcraft_dep_set_into_iter_recursive_free, [:pointer], :void

    # Uri support
    attach_function :pkgcraft_uri_str, [:pointer], String
    attach_function :pkgcraft_uri_free, [:pointer], :void
  end

  module Dep
    # Set of dependency objects.
    class DepSet
      include InspectStruct
      include Enumerable
      attr_reader :ptr

      # Create a DepSet from a pointer.
      def self.from_ptr(ptr, obj = nil)
        unless ptr.null?
          if obj.nil?
            case ptr[:kind]
            when 0
              obj = Dependencies.allocate
            when 1
              obj = License.allocate
            when 2
              obj = Properties.allocate
            when 3
              obj = RequiredUse.allocate
            when 4
              obj = Restrict.allocate
            when 5
              obj = SrcUri.allocate
            else
              "unsupported DepSet kind: #{ptr[:kind]}"
            end
          end
          obj.instance_variable_set(:@ptr, ptr)
        end

        obj
      end

      private_class_method :from_ptr

      # Iterator over a DepSet.
      class Iter
        include Enumerable

        def initialize(ptr)
          iter_p = C.pkgcraft_dep_set_into_iter(ptr)
          @ptr = FFI::AutoPointer.new(iter_p, C.method(:pkgcraft_dep_set_into_iter_free))
        end

        def each
          loop do
            ptr = C.pkgcraft_dep_set_into_iter_next(@ptr)
            break if ptr.null?

            yield DepSpec.send(:from_ptr, ptr)
          end
        end
      end

      private_constant :Iter

      def iter
        Iter.new(@ptr)
      end

      def each(&block)
        iter.each(&block)
      end

      def iter_flatten
        IterFlatten.new(self)
      end

      def iter_recursive
        IterRecursive.new(self)
      end

      def ==(other)
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? DepSet

        C.pkgcraft_dep_set_eq(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_dep_set_hash(@ptr) if @hash.nil?
        @hash
      end

      def to_s
        C.pkgcraft_dep_set_str(@ptr)
      end
    end

    # Flattened iterator over a DepSet or DepSpec.
    class IterFlatten
      include Enumerable

      def initialize(obj)
        case obj
        when DepSet
          iter_p = C.pkgcraft_dep_set_into_iter_flatten(obj.ptr)
        when DepSpec
          iter_p = C.pkgcraft_dep_spec_into_iter_flatten(obj.ptr)
        else
          raise TypeError.new("unsupported dep type: #{obj.class}")
        end

        @ptr = FFI::AutoPointer.new(iter_p, C.method(:pkgcraft_dep_set_into_iter_flatten_free))
        @unit = obj.ptr[:unit]
      end

      def each
        loop do
          ptr = C.pkgcraft_dep_set_into_iter_flatten_next(@ptr)
          break if ptr.null?

          case @unit
          when 0
            yield Dep.from_native(ptr)
          when 1
            s = ptr.read_string
            C.pkgcraft_str_free(ptr)
            yield s
          when 2
            yield Uri.from_native(ptr)
          else
            raise TypeError.new("unknown DepSet type: #{@unit}")
          end
        end
      end
    end

    private_constant :IterFlatten

    # Recursive iterator over a DepSet or DepSpec.
    class IterRecursive
      include Enumerable

      def initialize(obj)
        case obj
        when DepSet
          iter_p = C.pkgcraft_dep_set_into_iter_recursive(obj.ptr)
        when DepSpec
          iter_p = C.pkgcraft_dep_spec_into_iter_recursive(obj.ptr)
        else
          raise TypeError.new("unsupported dep type: #{obj.class}")
        end

        @ptr = FFI::AutoPointer.new(iter_p, C.method(:pkgcraft_dep_set_into_iter_recursive_free))
        @unit = obj.ptr[:unit]
      end

      def each
        loop do
          ptr = C.pkgcraft_dep_set_into_iter_recursive_next(@ptr)
          break if ptr.null?

          yield DepSpec.send(:from_ptr, ptr)
        end
      end
    end

    private_constant :IterRecursive

    # Set of package dependencies.
    class Dependencies < DepSet
      include Pkgcraft::Eapis

      def initialize(str = nil, eapi = EAPI_LATEST)
        eapi = Eapi.from_obj(eapi)
        ptr = C.pkgcraft_dep_set_dependencies(str.to_s, eapi)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr, self)
      end
    end

    # Set of LICENSE dependencies.
    class License < DepSet
      def initialize(str = nil)
        ptr = C.pkgcraft_dep_set_license(str.to_s)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr, self)
      end
    end

    # Set of PROPERTIES dependencies.
    class Properties < DepSet
      def initialize(str = nil)
        ptr = C.pkgcraft_dep_set_properties(str.to_s)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr, self)
      end
    end

    # Set of REQUIRED_USE dependencies.
    class RequiredUse < DepSet
      include Pkgcraft::Eapis

      def initialize(str = nil, eapi = EAPI_LATEST)
        eapi = Eapi.from_obj(eapi)
        ptr = C.pkgcraft_dep_set_required_use(str.to_s, eapi)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr, self)
      end
    end

    # Set of RESTRICT dependencies.
    class Restrict < DepSet
      def initialize(str = nil)
        ptr = C.pkgcraft_dep_set_restrict(str.to_s)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr, self)
      end
    end

    # Set of SRC_URI dependencies.
    class SrcUri < DepSet
      include Pkgcraft::Eapis

      def initialize(str = nil, eapi = EAPI_LATEST)
        eapi = Eapi.from_obj(eapi)
        ptr = C.pkgcraft_dep_set_src_uri(str.to_s, eapi)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr, self)
      end
    end

    # URI objects for the SRC_URI DepSet.
    class Uri < C::Uri
      def to_s
        C.pkgcraft_uri_str(@ptr)
      end
    end
  end
end
