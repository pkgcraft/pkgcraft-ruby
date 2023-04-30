# frozen_string_literal: true

module Pkgcraft
  # FFI bindings for Eapi related functionality
  module C
    # Wrapper for Eapi pointers
    class Eapi < Pointer
      def self.from_native(value, _context = nil)
        if Pkgcraft::Eapis.const_defined?(:EAPIS)
          id = C.pkgcraft_eapi_as_str(value)
          Pkgcraft::Eapis::EAPIS[id]
        else
          obj = super(value)
          obj.instance_variable_set(:@hash, C.pkgcraft_eapi_hash(value))
          obj.instance_variable_set(:@id, C.pkgcraft_eapi_as_str(value))
          dep_keys = C.ptr_to_string_array(value, C.method(:pkgcraft_eapi_dep_keys))
          obj.instance_variable_set(:@dep_keys, dep_keys.freeze)
          obj
        end
      end
    end

    typedef :pointer, :eapi_ptr
    attach_function :pkgcraft_eapi_as_str, [:eapi_ptr], String
    attach_function :pkgcraft_eapi_cmp, [Eapi, Eapi], :int
    attach_function :pkgcraft_eapi_has, [Eapi, :string], :bool
    attach_function :pkgcraft_eapi_hash, [:eapi_ptr], :uint64
    attach_function :pkgcraft_eapi_dep_keys, [:eapi_ptr, LenPtr.by_ref], :pointer
    attach_function :pkgcraft_eapis_official, [LenPtr.by_ref], :pointer
    attach_function :pkgcraft_eapis, [LenPtr.by_ref], :pointer
    attach_function :pkgcraft_eapis_range, [:string, LenPtr.by_ref], :pointer
  end

  # EAPI support
  module Eapis
    # EAPI object
    class Eapi < C::Eapi
      include InspectPointerRender
      include Comparable
      attr_reader :hash, :dep_keys

      # Try to convert an object to an Eapi object.
      def self.from_obj(obj)
        return obj if obj.is_a? Eapi

        if obj.is_a? String
          eapi = EAPIS[obj]
          return eapi unless eapi.nil?

          raise "unknown EAPI: #{obj}"
        end

        raise TypeError.new("unsupported Eapi type: #{obj.class}")
      end

      # Check if an EAPI has a given feature.
      def has(feature)
        C.pkgcraft_eapi_has(self, feature.to_s)
      end

      def to_s
        @id
      end

      def <=>(other)
        C.pkgcraft_eapi_cmp(self, other)
      end

      alias eql? ==
    end

    # Convert an EAPI range into an ordered set of Eapi objects.
    def self.range(str)
      length = C::LenPtr.new
      ptr = C.pkgcraft_eapis_range(str.to_s, length)
      raise Error::PkgcraftError if ptr.null?

      c_eapis = ptr.get_array_of_pointer(0, length[:value])
      eapis = []
      c_eapis.each do |eapi_ptr|
        id = C.pkgcraft_eapi_as_str(eapi_ptr)
        eapis.append(EAPIS[id])
      end

      C.pkgcraft_array_free(ptr, length[:value])
      eapis
    end

    # Return the mapping of all official EAPIs.
    def self.eapis_official
      eapi_objs = C.ptr_to_obj_array(
        Pkgcraft::Eapis::Eapi,
        C.method(:pkgcraft_eapis_official)
      )

      eapis = {}
      eapi_objs.each do |eapi|
        id = eapi.to_s
        # set constants for all official EAPIs, e.g. EAPI0, EAPI1, ...
        Eapis.const_set("EAPI#{id}", eapi)
        eapis[id] = eapi
      end

      @eapi_latest_official = eapi_objs.last
      eapis
    end

    private_class_method :eapis_official

    # Hash of all official EAPIs.
    EAPIS_OFFICIAL = eapis_official.freeze

    # Reference to the most recent, official EAPI.
    EAPI_LATEST_OFFICIAL = @eapi_latest_official.freeze

    # Return the mapping of all EAPIs.
    def self.eapis
      eapi_objs = C.ptr_to_obj_array(
        Pkgcraft::Eapis::Eapi,
        C.method(:pkgcraft_eapis)
      )

      eapis = {}
      eapis.update(EAPIS_OFFICIAL)
      eapi_objs[eapis.length..].each do |eapi|
        eapis[eapi.to_s] = eapi
      end

      @eapi_latest = eapi_objs.last
      eapis
    end

    private_class_method :eapis

    # Hash of all EAPIs.
    EAPIS = eapis.freeze

    # Reference to the most recent EAPI.
    EAPI_LATEST = @eapi_latest.freeze
  end
end
