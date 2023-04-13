# frozen_string_literal: true

module Pkgcraft
  module Repos
    # Fake package repo.
    class Fake < Repo
      def initialize(cpvs_or_path = [], id: nil, priority: 0)
        if [String, Pathname].any? { |c| cpvs_or_path.is_a? c }
          super(cpvs_or_path, id, priority)
        else
          cpvs = cpvs_or_path
          c_cpvs = FFI::MemoryPointer.new(:pointer, cpvs.length)
          c_cpvs.write_array_of_pointer(cpvs.map { |s| FFI::MemoryPointer.from_string(s) })

          # generate a semi-random repo ID if none was given
          if id.nil?
            rand = (0...10).map { ("a".."z").to_a[rand(26)] }.join
            id = "fake-#{rand}"
          end

          ptr = C.pkgcraft_repo_fake_new(id, priority, c_cpvs, cpvs.length)
          Repo.send(:from_ptr, ptr, false, self)
        end
      end
    end
  end
end
