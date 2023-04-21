# frozen_string_literal: true

module Pkgcraft
  module Repos
    # Fake package repo.
    class Fake < Repo
      def initialize(cpvs_or_path = [], id: nil, priority: 0)
        if [String, Pathname].any? { |c| cpvs_or_path.is_a? c }
          super(cpvs_or_path, id, priority)
        else
          # generate a semi-random repo ID if none was given
          if id.nil?
            rand = (0...10).map { ("a".."z").to_a[rand(26)] }.join
            id = "fake-#{rand}"
          end

          c_cpvs, length = C.iter_to_ptr(cpvs_or_path)
          ptr = C.pkgcraft_repo_fake_new(id, priority, c_cpvs, length)
          Repo.send(:from_ptr, ptr, false, self)
        end
      end

      def extend(cpvs)
        c_cpvs, length = C.iter_to_ptr(cpvs)
        ptr = C.pkgcraft_repo_fake_extend(@ptr, c_cpvs, length)
        raise Error::PkgcraftError if ptr.null?
      end
    end
  end
end
