module Hallon
  # AlbumBrowse objects are for retrieving additional data from
  # an album that cannot otherwise be acquired. This includes
  # tracks, reviews, copyright information.
  #
  # @see Album
  class AlbumBrowse < Base
    include Hallon::Observable

    # Creates an AlbumBrowse instance from an Album.
    #
    # @note Use {Album#browse} to browse an Album.
    # @param [Album, FFI::Pointer] album
    def initialize(album)
      session = Hallon::Session.instance
      album   = album.pointer if album.respond_to?(:pointer)
      @callback = proc { trigger(:load) }

      albumbrowse = Spotify::albumbrowse_create(session.pointer, album, @callback, nil)
      @pointer    = Spotify::Pointer.new(albumbrowse, :albumbrowse, false)
    end

    # @return [Boolean] true if the album is loaded
    def loaded?
      Spotify::albumbrowse_is_loaded(@pointer)
    end

    # @see Error
    # @return [Symbol] album error status
    def error
      Spotify::albumbrowse_error(@pointer)
    end

    # @return [String] album review
    def review
      Spotify::albumbrowse_review(@pointer)
    end

    # @return [Artist] artist performing this album
    def artist
      pointer = Spotify::albumbrowse_artist(@pointer)
      Hallon::Artist.new(pointer) unless pointer.null?
    end

    # @return [Album] album this object is browsing
    def album
      pointer = Spotify::albumbrowse_album(@pointer)
      Hallon::Album.new(pointer) unless pointer.null?
    end

    # @return [Enumerator<String>] list of copyright notices
    def copyrights
      size = Spotify::albumbrowse_num_copyrights(@pointer)
      Hallon::Enumerator.new(size) do |i|
        Spotify::albumbrowse_copyright(@pointer, i)
      end
    end

    # @return [Enumerator<Track>] list of tracks
    def tracks
      size = Spotify::albumbrowse_num_tracks(@pointer)
      Hallon::Enumerator.new(size) do |i|
        pointer = Spotify::albumbrowse_track(@pointer, i)
        Hallon::Track.new(pointer) unless pointer.null?
      end
    end
  end
end
