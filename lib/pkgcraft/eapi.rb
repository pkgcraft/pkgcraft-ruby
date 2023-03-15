# frozen_string_literal: true

module Pkgcraft
  # EAPI support
  module Eapi
    # EAPI object
    class Eapi
      include Comparable
      attr_reader :ptr

      def initialize(ptr)
        @ptr = ptr
        @id, c_str = C.pkgcraft_eapi_as_str(ptr)
        C.pkgcraft_str_free(c_str)
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

    # Try to convert an object to an Eapi object.
    def self.from_obj(obj)
      return obj if obj.is_a? Eapi

      eapi = self.EAPIS[obj.to_s]
      return eapi unless eapi.nil?

      raise "unknown EAPI: #{obj}" if obj.is_a? String

      raise TypeError.new("unsupported Eapi type: #{obj.class}")
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

    # rubocop:disable Naming/MethodName

    # Hash of all official EAPIs.
    def self.EAPIS_OFFICIAL
      if @eapis_official.nil?
        length = C::LenPtr.new
        ptr = C.pkgcraft_eapis_official(length)
        c_eapis = ptr.read_array_of_type(:pointer, :read_pointer, length[:value])
        eapis = {}
        (0...length[:value]).each do |i|
          eapi = Eapi.new(c_eapis[i])
          eapis[eapi.to_s] = eapi
          @eapi_latest_official = eapi if i == length[:value] - 1
        end
        C.pkgcraft_eapis_free(ptr, length[:value])
        @eapis_official = eapis
      end
      @eapis_official
    end

    # Has of all EAPIs.
    def self.EAPIS
      if @eapis.nil?
        length = C::LenPtr.new
        ptr = C.pkgcraft_eapis(length)
        c_eapis = ptr.read_array_of_type(:pointer, :read_pointer, length[:value])
        eapis = self.EAPIS_OFFICIAL.clone
        (eapis.length...length[:value]).each do |i|
          eapi = Eapi.new(c_eapis[i])
          eapis[eapi.to_s] = eapi
          @eapi_latest = eapi if i == length[:value] - 1
        end
        C.pkgcraft_eapis_free(ptr, length[:value])
        @eapis = eapis
      end
      @eapis
    end

    # Reference to the most recent, official EAPI.
    def self.LATEST_OFFICIAL
      self.EAPIS_OFFICIAL if @eapi_latest_official.nil?
      @eapi_latest_official
    end

    # Reference to the most recent EAPI.
    def self.LATEST
      self.EAPIS if @eapi_latest.nil?
      @eapi_latest
    end

    # rubocop:enable Naming/MethodName
  end
end
