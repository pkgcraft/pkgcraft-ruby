# frozen_string_literal: true

module Pkgcraft
  # Package support
  module Pkg
    # Create a Pkg from a pointer.
    def self.from_ptr(ptr)
      format = C.pkgcraft_pkg_format(ptr)
      case format
      when 0
        obj = Ebuild.allocate
      when 1
        obj = Fake.allocate
      else
        "unsupported pkg format: #{format}"
      end

      ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_pkg_free))
      obj.instance_variable_set(:@ptr, ptr)
      obj
    end

    private_class_method :from_ptr

    # Generic package.
    class Pkg
      include Comparable
      attr_reader :ptr

      def <=>(other)
        return C.pkgcraft_pkg_cmp(@ptr, other.ptr) if other.is_a? Pkg

        raise TypeError.new("invalid type: #{other.class}")
      end

      def hash
        @_hash = C.pkgcraft_pkg_hash(@ptr) if @_hash.nil?
        @_hash
      end

      def to_s
        s, c_str = C.pkgcraft_pkg_str(@ptr)
        C.pkgcraft_str_free(c_str)
        s
      end
    end
  end
end
