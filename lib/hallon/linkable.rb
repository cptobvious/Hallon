# coding: utf-8
module Hallon
  # Methods shared between objects that can be created from Spotify URIs,
  # or can be turned into Spotify URIs.
  #
  # @note Linkable is part of Hallons’ private API. You probably do not
  #       not need to care about these methods.
  #
  # @private
  module Linkable
    # ClassMethods adds `#from_link` and `#to_link` DSL methods, which
    # essentially are convenience methods for defining the way to convert
    # a link to a pointer of a given Spotify object type.
    module ClassMethods
      # Defines `#from_link`, used in converting a link to a pointer. You
      # can either pass it a `method_name`, or a `type` and a block.
      #
      # @overload from_link(method_name)
      #   Define `#from_link` simply by giving the name of the method,
      #   minus the `link_` prefix.
      #
      #   @example
      #     class Album
      #       include Linkable
      #
      #       from_link :as_album # => Spotify.link_as_album(pointer, *args)
      #       # ^ is roughly equivalent to:
      #       def from_link(link, *args)
      #         unless link.is_a?(Spotify::Link)
      #           link = Link.new(link).pointer(:album)
      #         end
      #
      #         Spotify.link_as_album(link)
      #       end
      #     end
      #
      #   @param [Symbol] method_name
      #
      # @overload from_link(type) { |*args| … }
      #   Define `#from_link` to use the given block to convert an object
      #   from a link. The link is converted to a pointer and typechecked
      #   to be of the same type as `type` before given to the block.
      #
      #   @example
      #     class User
      #       include Linkable
      #
      #       from_link :profile do |pointer|
      #         Spotify.link_as_user(pointer)
      #       end
      #       # ^ is roughly equivalent to:
      #       def from_link(link, *args)
      #         unless link.is_a?(Spotify::Link)
      #           link = Link.new(link).pointer(:profile)
      #         end
      #
      #         Spotify.link_as_user(link)
      #       end
      #     end
      #
      #   @param [#to_s] type link type
      #   @yield [link, *args] called when conversion is needed from Link pointer
      #   @yieldparam [Spotify::Link] link
      #   @yieldparam *args any extra arguments given to `#from_link`
      #
      # @note Private API. You probably do not need to care about this method.
      def from_link(as_object, &block)
        block ||= Spotify.method(:"link_#{as_object}")
        type    = as_object.to_s[/^(as_)?([^_]+)/, 2].to_sym

        define_method(:from_link) do |link, *args|
          unless link.is_a?(Spotify::Link)
            link = Link.new(link).pointer(type)
          end

          instance_exec(link, *args, &block)
        end

        private :from_link
      end

      # Defines `#to_link` method, used in converting the object to a {Link}.
      #
      # @example
      #   class Artist
      #     include Linkable
      #
      #     to_link :from_artist
      #     # ^ is the same as:
      #     def to_link(*args)
      #       link = Spotify.link_create_from_artist(pointer, *args)
      #       Link.new(link)
      #     end
      #   end
      #
      # @param [Symbol] cmethod name of the C method, say `from_artist` in `Spotify.link_create_from_artist`.
      # @return [Link, nil]
      def to_link(cmethod)
        define_method(:to_link) do |*args|
          link = Spotify.__send__(:"link_create_#{cmethod}", pointer, *args)
          Link.from(link)
        end
      end
    end

    # Will extend `other` with ClassMethods on inclusion.
    #
    # @param [#extend] other
    def self.included(other)
      other.extend ClassMethods
    end

    # Converts the Linkable first to a Link, and then that link to a String.
    #
    # @note Returns an empty string if the #to_link call fails.
    # @return [String]
    def to_str
      link = to_link
      link &&= link.to_str
      link.to_s
    end

    # Compare the Linkable to other. If other is a Linkable, also
    # compare their `to_link` if necessary.
    #
    # @param [Object] other
    # @return [Boolean]
    def ===(other)
      super or if other.respond_to?(:to_link)
        to_link == other.to_link
      end
    end
  end
end
