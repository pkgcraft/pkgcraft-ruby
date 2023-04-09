# frozen_string_literal: true

module Pkgcraft
  module Repo
    # Package repository.
    class Base
      attr_reader :id

      # Create a Repo from a pointer.
      def self._from_ptr(ptr, ref)
        ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_free)) unless ref
        obj = allocate
        obj.instance_variable_set(:@ptr, ptr)
        id, c_str = C.pkgcraft_repo_id(ptr)
        C.pkgcraft_str_free(c_str)
        obj.instance_variable_set(:@id, id)
        obj
      end

      def to_s
        @id
      end
    end
  end
end
