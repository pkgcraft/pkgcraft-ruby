# frozen_string_literal: true

module Pkgcraft
  module Repo
    # Package repo.
    class Base
      include Comparable
      attr_reader :id
      attr_reader :ptr

      # Create a Repo from a pointer.
      def self._from_ptr(ptr, ref)
        format = C.pkgcraft_repo_format(ptr)
        case format
        when 0
          obj = Repo::Ebuild.allocate
        when 1
          obj = Repo::Fake.allocate
        else
          "unsupported repo format: #{format}"
        end

        ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_free)) unless ref
        obj.instance_variable_set(:@ptr, ptr)
        id, c_str = C.pkgcraft_repo_id(ptr)
        C.pkgcraft_str_free(c_str)
        obj.instance_variable_set(:@id, id)
        obj
      end

      def <=>(other)
        return C.pkgcraft_repo_cmp(@ptr, other.ptr) if other.is_a? Repo

        raise TypeError.new("invalid type: #{other.class}")
      end

      def hash
        @_hash = C.pkgcraft_repo_hash(@ptr) if @_hash.nil?
        @_hash
      end

      def to_s
        @id
      end
    end
  end
end
