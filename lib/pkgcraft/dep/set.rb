# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for DepSet related functionality
  module C
    # Wrapper for DepSet objects.
    class DepSet < FFI::ManagedStruct
      layout :set, :int,
             :ptr, :pointer

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
    attach_function :pkgcraft_dep_set_len, [:DepSet], :uint64
    attach_function :pkgcraft_dep_set_is_empty, [:DepSet], :bool
    attach_function :pkgcraft_dep_set_parse, [:string, Eapi, :int], :DepSet
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
    attach_function :pkgcraft_uri_filename, [Uri], String
    attach_function :pkgcraft_uri_str, [Uri], String
    attach_function :pkgcraft_uri_uri, [Uri], String
    attach_function :pkgcraft_uri_free, [:pointer], :void
  end

  module Dep
    # Set of dependency objects.
    class DepSet
      include Pkgcraft::Eapis
      include InspectStruct
      include Enumerable
      attr_reader :ptr

      # Create a DepSet from a pointer.
      def self.from_ptr(ptr, obj = nil)
        unless ptr.null?
          if obj.nil?
            case ptr[:set]
            when 0
              obj = Dependencies.allocate
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
              "unsupported DepSet kind: #{ptr[:set]}"
            end
          end
          obj.instance_variable_set(:@ptr, ptr)
        end

        obj
      end

      private_class_method :from_ptr

      def initialize(str = nil, eapi = EAPI_LATEST)
        eapi = Eapi.from_obj(eapi)
        if is_a? Dependencies
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
          "unsupported DepSet kind: #{ptr[:set]}"
        end
        ptr = C.pkgcraft_dep_set_parse(str.to_s, eapi, kind)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr, self)
      end

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
        raise TypeError.new("invalid type: #{other.class}") unless other.is_a? DepSet

        C.pkgcraft_dep_set_eq(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @hash = C.pkgcraft_dep_set_hash(@ptr) if @hash.nil?
        @hash
      end

      def length
        C.pkgcraft_dep_set_len(@ptr)
      end

      def empty?
        C.pkgcraft_dep_set_is_empty(@ptr)
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
        @set = obj.ptr[:set]
      end

      def each
        loop do
          ptr = C.pkgcraft_dep_set_into_iter_flatten_next(@ptr)
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
        @set = obj.ptr[:set]
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

    class Dependencies < DepSet; end
    class License < DepSet; end
    class Properties < DepSet; end
    class RequiredUse < DepSet; end
    class Restrict < DepSet; end
    class SrcUri < DepSet; end

    # URI objects for the SRC_URI DepSet.
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
