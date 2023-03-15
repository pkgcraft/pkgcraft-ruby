# frozen_string_literal: true

module Pkgcraft
  # EAPI support
  module Eapis
    # EAPI object
    class Eapi
      include Comparable
      attr_reader :ptr

      # Create a new Eapi object from a given pointer.
      def initialize(ptr)
        @ptr = ptr
        @id, c_str = C.pkgcraft_eapi_as_str(ptr)
        C.pkgcraft_str_free(c_str)
      end

      # Try to convert an object to an Eapi object.
      def self.from_obj(obj)
        return obj if obj.is_a? Eapi

        eapi = EAPIS[obj.to_s]
        return eapi unless eapi.nil?

        raise "unknown EAPI: #{obj}" if obj.is_a? String

        raise TypeError.new("unsupported Eapi type: #{obj.class}")
      end

      # Check if an EAPI has a given feature.
      def has(feature)
        C.pkgcraft_eapi_has(@ptr, feature.to_s)
      end

      def to_s
        @id
      end

      def <=>(other)
        C.pkgcraft_eapi_cmp(@ptr, other.ptr)
      end

      alias eql? ==

      def hash
        @_hash = C.pkgcraft_eapi_hash(@ptr) if @_hash.nil?

        @_hash
      end
    end

    # Convert an EAPI range into an ordered set of Eapi objects.
    def self.range(str)
      length = C::LenPtr.new
      ptr = C.pkgcraft_eapis_range(str, length)
      raise Error::PkgcraftError if ptr.null?

      c_eapis = ptr.read_array_of_type(:pointer, :read_pointer, length[:value])
      eapis = []
      (0...length[:value]).each do |i|
        eapi = Eapi.new(c_eapis[i])
        eapis.append(eapi)
      end
      eapis
    end

    # Return the mapping of all official EAPIs.
    def self.eapis_official
      length = C::LenPtr.new
      ptr = C.pkgcraft_eapis_official(length)
      c_eapis = ptr.read_array_of_type(:pointer, :read_pointer, length[:value])
      eapis = {}
      (0...length[:value]).each do |i|
        eapi = Eapi.new(c_eapis[i])
        # set constants for all official EAPIs, e.g. EAPI0, EAPI1, ...
        Eapis.const_set("EAPI#{i}", eapi)
        eapis[eapi.to_s] = eapi
        @eapi_latest_official = eapi if i == length[:value] - 1
      end
      C.pkgcraft_eapis_free(ptr, length[:value])
      eapis
    end

    private_class_method :eapis_official

    # Hash of all official EAPIs.
    EAPIS_OFFICIAL = eapis_official

    # Reference to the most recent, official EAPI.
    EAPI_LATEST_OFFICIAL = @eapi_latest_official

    # Return the mapping of all EAPIs.
    def self.eapis
      length = C::LenPtr.new
      ptr = C.pkgcraft_eapis(length)
      c_eapis = ptr.read_array_of_type(:pointer, :read_pointer, length[:value])
      eapis = EAPIS_OFFICIAL.clone
      (eapis.length...length[:value]).each do |i|
        eapi = Eapi.new(c_eapis[i])
        eapis[eapi.to_s] = eapi
        @eapi_latest = eapi if i == length[:value] - 1
      end
      C.pkgcraft_eapis_free(ptr, length[:value])
      eapis
    end

    private_class_method :eapis

    # Hash of all EAPIs.
    EAPIS = eapis

    # Reference to the most recent EAPI.
    EAPI_LATEST = @eapi_latest
  end
end
