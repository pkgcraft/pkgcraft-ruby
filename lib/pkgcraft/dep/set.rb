# frozen_string_literal: true

module Pkgcraft
  module Dep
    # Set of dependency objects.
    class DepSet
      attr_reader :ptr

      # Create a DepSet from a pointer.
      def self.from_ptr(ptr, obj = nil)
        unless ptr.null?
          if obj.nil?
            case ptr[:kind]
            when 0
              obj = Dependencies.allocate
            else
              "unsupported DepSet kind: #{ptr[:kind]}"
            end
          end
          obj.instance_variable_set(:@ptr, ptr)
        end

        obj
      end

      private_class_method :from_ptr

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
    end

    # Set of package dependencies.
    class Dependencies < DepSet
      include Pkgcraft::Eapis

      def initialize(str = nil, eapi = EAPI_LATEST)
        eapi = Eapi.from_obj(eapi) unless eapi.nil?
        ptr = C.pkgcraft_dep_set_dependencies(str.to_s, eapi.ptr)
        raise Error::PkgcraftError if ptr.null?

        DepSet.send(:from_ptr, ptr, self)
      end
    end
  end
end
