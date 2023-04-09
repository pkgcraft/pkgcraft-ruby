# frozen_string_literal: true

module Pkgcraft
  # Repo support
  module Repo
    # Create a Repo from a pointer.
    def self.from_ptr(ptr, ref)
      format = C.pkgcraft_repo_format(ptr)
      case format
      when 0
        obj = Ebuild.allocate
      when 1
        obj = Fake.allocate
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

    private_class_method :from_ptr

    # Package repo.
    class Repo
      include Comparable
      include Enumerable
      attr_reader :id
      attr_reader :ptr

      # Iterator over a repo.
      class Iter
        def initialize(repo)
          ptr = C.pkgcraft_repo_iter(repo.ptr)
          @ptr = FFI::AutoPointer.new(ptr, C.method(:pkgcraft_repo_iter_free))
        end

        def each
          loop do
            ptr = C.pkgcraft_repo_iter_next(@ptr)
            break if ptr.null?

            yield Pkg.send(:from_ptr, ptr)
          end
        end
      end

      private_constant :Iter

      def each(&block)
        Iter.new(self).each(&block)
      end

      def path
        if @_path.nil?
          path, c_str = C.pkgcraft_repo_path(@ptr)
          @_path = Pathname.new(path)
          C.pkgcraft_str_free(c_str)
        end
        @_path
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
