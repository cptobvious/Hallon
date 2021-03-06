# coding: utf-8
module Hallon
  # All objects in Hallon are mere representations of Spotify objects.
  # Hallon::Base covers basic functionality shared by all of these.
  class Base
    # @param [#nil?, #null?] pointer
    # @return [self, nil] a new instance of self, unless given pointer is #null?
    def self.from(pointer, *args, &block)
      is_nil  = pointer.nil?
      is_null = pointer.null? if pointer.respond_to?(:null?)

      unless is_nil or is_null
        new(pointer, *args, &block)
      end
    end

    # Underlying FFI pointer.
    #
    # @return [FFI::Pointer]
    attr_reader :pointer

    # True if both objects represent the *same* object.
    #
    # @param [Object] other
    # @return [Boolean]
    def ==(other)
      if other.respond_to?(:pointer)
        pointer == other.pointer
      else
        super
      end
    end

    # Default string representation of self.
    def to_s
      name    = self.class.name
      address = pointer.address.to_s(16)
      "<#{name} address=0x#{address}>"
    end

    private

      # See {Linkable::ClassMethods#to_link}.
      #
      # @macro [attach] to_link
      #   @method to_link
      #   @scope  instance
      #   @return [Hallon::Link] {Link} for the current object.
      def self.to_link(cmethod)
        # this is here to work around a YARD limitation, see
        # {Linkable} for the actual source
      end

      # See {Linkable::ClassMethods#from_link}.
      #
      # @macro [attach] from_link
      #   @method from_link
      #   @scope  instance
      #   @visibility private
      #   @param  [String, Hallon::Link, Spotify::Link] link
      #   @return [Spotify::Link] pointer representation of given link.
      def self.from_link(as_object, &block)
        # this is here to work around a YARD limitation, see
        # {Linkable} for the actual source
      end

      # The current Session instance.
      #
      # @return [Session]
      def session
        Session.instance
      end

      # Convert a given object to a pointer by best of ability.
      #
      # @param [Spotify::ManagedPointer, String, Link] resource
      # @return [Spotify::ManagedPointer]
      # @raise [TypeError] when the pointer is of the wrong type
      # @raise [ArgumentError] when pointer could not be created, or null
      def to_pointer(resource, type, *args)
        if resource.is_a?(FFI::Pointer) and not resource.is_a?(Spotify::ManagedPointer)
          raise TypeError, "Hallon does not support raw FFI::Pointers, wrap it in a Spotify::ManagedPointer"
        end

        pointer = if resource.is_a?(type)
          resource
        elsif is_linkable? and resource.is_a?(Spotify::Link)
          from_link(resource, *args)
        elsif is_linkable? and Link.valid?(resource)
          from_link(resource, *args)
        elsif block_given?
          yield(resource, *args)
        end

        if pointer.nil? or pointer.null?
          raise ArgumentError, "#{resource.inspect} could not be converted to a spotify #{type} pointer"
        elsif not pointer.is_a?(type)
          raise TypeError, "“#{resource}” is a #{resource.class}, #{type} expected"
        else
          pointer
        end
      end

      # @return [Boolean] true if the object can convert links to pointers
      def is_linkable?
        respond_to?(:from_link, true)
      end
  end
end
