# frozen_string_literal: true

module Pkgcraft
  # Pointer wrapper classes for Dep related functionality.
  module C
    # Wrapper for Cpn pointers
    class Cpn < AutoPointer
      def self.release(ptr)
        C.pkgcraft_cpn_free(ptr)
      end
    end

    # Wrapper for Cpv pointers
    class Cpv < AutoPointer
      def self.release(ptr)
        C.pkgcraft_cpv_free(ptr)
      end
    end

    # Wrapper for Dep pointers
    class Dep < AutoPointer
      def self.release(ptr)
        C.pkgcraft_dep_free(ptr)
      end
    end

    # Wrapper for version pointers
    class Version < AutoPointer
      def self.release(ptr)
        C.pkgcraft_version_free(ptr)
      end
    end

    # Wrapper for revision pointers
    class Revision < AutoPointer
      def self.release(ptr)
        C.pkgcraft_revision_free(ptr)
      end
    end
  end
end

require_relative "dep/cpn"
require_relative "dep/cpv"
require_relative "dep/pkg"
require_relative "dep/base"
require_relative "dep/version"
