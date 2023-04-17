# frozen_string_literal: true

module Pkgcraft
  module Dep
    # Set of dependency objects.
    class DepSet
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
        @_hash = C.pkgcraft_dep_set_hash(@ptr) if @_hash.nil?
        @_hash
      end

      def to_s
        s, c_str = C.pkgcraft_dep_set_str(@ptr)
        C.pkgcraft_str_free(c_str)
        s
      end

      def inspect
        "#<#{self.class} '#{self}'>"
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
            yield Dep.send(:from_ptr, C::Dep.new(ptr))
          when 1
            s = FFI::Pointer.read_string(ptr)
            C.pkgcraft_str_free(ptr)
            yield s
          when 2
            yield Uri.send(:from_ptr, ptr)
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
        ptr = C.pkgcraft_dep_set_dependencies(str.to_s, eapi.ptr)
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
        ptr = C.pkgcraft_dep_set_required_use(str.to_s, eapi.ptr)
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
        ptr = C.pkgcraft_dep_set_src_uri(str.to_s, eapi.ptr)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr, self)
      end
    end

    # URI objects for the SRC_URI DepSet.
    class Uri
      attr_reader :ptr

      # Create a Uri from a pointer.
      def self.from_ptr(ptr)
        obj = allocate
        ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_uri_free))
        obj.instance_variable_set(:@ptr, ptr)
        obj
      end

      private_class_method :from_ptr

      def to_s
        s, c_str = C.pkgcraft_uri_str(@ptr)
        C.pkgcraft_str_free(c_str)
        s
      end
    end
  end
end
