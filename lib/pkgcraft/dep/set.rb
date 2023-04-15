# frozen_string_literal: true

module Pkgcraft
  module Dep
    # Set of dependency objects.
    class DepSet
      # Create a DepSet from a pointer.
      def self.from_ptr(ptr, obj = nil)
        unless ptr.null?
          if obj.nil?
            case ptr[:kind]
            when 0
              obj = Dependencies.allocate
            else
              "unsupported DepSet kind: #{ptr[:kind]}"
            end
          end
          obj.instance_variable_set(:@ptr, ptr)
        end

        obj
      end

      private_class_method :from_ptr
    end

    class Dependencies < DepSet
    end
  end
end
