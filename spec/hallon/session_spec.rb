# coding: utf-8
describe Hallon::Session do
  it { Hallon::Session.should_not respond_to :new }

  describe ".initialize and .instance" do
    before { Hallon.instance_eval { @__instance = nil } }
    after  { Hallon.instance_eval { @__instance = nil } }

    it "should fail if calling instance before initialize" do
      expect { Hallon.instance }.to raise_error
    end

    it "should fail if calling initialize twice" do
      expect {
        Hallon.initialize
        Hallon.initialize
      }.to raise_error
    end

    it "should succeed if everything is right" do
      expect { Hallon::Session.initialize('appkey_good') }.to_not raise_error
    end
  end

  describe ".new" do
    it "should require an application key" do
      expect { Hallon::Session.send(:new) }.to raise_error(ArgumentError)
    end

    it "should fail on an invalid application key" do
      expect { create_session(false) }.to raise_error(Hallon::Error, /BAD_APPLICATION_KEY/)
    end

    it "should fail on a small user-agent of multibyte chars (> 255 characters)" do
      expect { create_session(true, :user_agent => 'ö' * 128) }.to raise_error(ArgumentError)
    end

    it "should fail on a huge user agent (> 255 characters)" do
      expect { create_session(true, :user_agent => 'a' * 256) }.to raise_error(ArgumentError)
    end

    it "should extract the proxy username and password" do
      session = create_session(true, :proxy => "socks5://kim:pass@batm.an")
      session.options[:proxy].should eq "socks5://batm.an"
      session.options[:proxy_username].should eq "kim"
      session.options[:proxy_password].should eq "pass"
    end

    it "should not override the given username or password" do
      session = create_session(true, :proxy => "socks5://kim:pass@batm.an", :proxy_username => "batman", :proxy_password => "hidden identity")
      session.options[:proxy].should eq "socks5://batm.an"
      session.options[:proxy_username].should eq "batman"
      session.options[:proxy_password].should eq "hidden identity"
    end
  end

  describe "options" do
    subject { session.options }
    its([:user_agent]) { should == options[:user_agent] }
    its([:settings_location]) { should == options[:settings_location] }
    its([:cache_location]) { should == options[:cache_location] }

    its([:initially_unload_playlists]) { should == false }
    its([:compress_playlists]) { should == true }
    its([:dont_save_metadata_for_playlists]) { should == false }
  end

  describe "#container" do
    it "should return the sessions’ playlist container" do
      session.login 'burgestrand', 'pass'
      session.container.should eq Hallon::PlaylistContainer.new(mock_container)
    end

    it "should return nil if not logged in" do
      session.container.should be_nil
    end
  end

  describe "#process_events" do
    it "should return the timeout" do
      session.process_events.should be_a Fixnum
    end
  end

  describe "#relogin" do
    it "should raise if no credentials have been saved" do
      expect { session.relogin }.to raise_error(Spotify::Error)
    end

    it "should not raise if credentials have been saved" do
      session.login 'Kim', 'pass', true
      session.logout
      expect { session.relogin }.to_not raise_error
      session.should be_logged_in
    end
  end

  describe "#username" do
    it "should be nil if no username is stored in libspotify" do
      session.username.should eq nil
    end

    it "should retrieve the current user’s name if logged in" do
      session.login 'Kim', 'pass'
      session.username.should eq 'Kim'
    end
  end

  describe "#remembered_user" do
    it "should be nil if no username is stored in libspotify" do
      session.remembered_user.should eq nil
    end

    it "should retrieve the remembered username if stored" do
      session.login 'Kim', 'pass', true
      session.remembered_user.should eq 'Kim'
    end
  end

  describe "#forget_me!" do
    it "should forget the currently stored user credentials" do
      session.login 'Kim', 'pass', true
      session.remembered_user.should eq 'Kim'
      session.forget_me!
      session.remembered_user.should eq nil
    end
  end

  describe "#login" do
    it "should raise an error when given empty credentials" do
      expect { session.login '', 'pass' }.to raise_error(ArgumentError)
      expect { session.login 'Kim', '' }.to raise_error(ArgumentError)
    end

    it "should login with a blob when given a blob" do
      spotify_api.should_receive(:session_login).with(anything, 'Kim', nil, false, 'blob')
      session.login 'Kim', Hallon::Blob('blob')
    end

    it "should not login with a blob when not given a blob" do
      spotify_api.should_receive(:session_login).with(anything, 'Kim', 'pass', false, nil)
      session.login 'Kim', 'pass'
    end
  end

  describe "#logout" do
    it "should check logged in status" do
      session.should_receive(:logged_in?).once.and_return(false)
      expect { session.logout }.to_not raise_error
    end
  end

  describe "#user" do
    it "should return the logged in user" do
      session.login 'Kim', 'pass'
      session.user.name.should eq 'Kim'
    end

    it "should return nil if not logged in" do
      session.user.should be_nil
    end
  end

  describe "#country" do
    it "should retrieve the current sessions’ country as a string" do
      session.country.should eq 'SE'
    end
  end

  describe "#star and #unstar" do
    it "should be able to star and unstar tracks" do
      # for track#starred?
      Hallon::Session.should_receive(:instance).exactly(6).times.and_return(session)

      tracks = [mock_track, mock_track_two]
      tracks.map! { |x| Hallon::Track.new(x) }
      tracks.all?(&:starred?).should be_true # starred by default

      session.unstar(*tracks)
      tracks.none?(&:starred?).should be_true

      session.star(tracks[0])
      tracks[0].should be_starred
      tracks[1].should_not be_starred
    end
  end

  describe "#private= and #private?" do
    it "sets session privacy mode" do
      session.private = false
      session.should_not be_private
      session.private = true
      session.should be_private
    end
  end

  describe "#cache_size" do
    it "should default to 0" do
      session.cache_size.should eq 0
    end

    it "should be settable" do
      session.cache_size = 10
      session.cache_size.should eq 10
    end
  end

  describe ".connection_types" do
    subject { Hallon::Session.connection_types }

    it { should be_an Array }
    it { should_not be_empty }
    it { should include :wifi }
  end

  describe "#connection_type=" do
    it "should fail given an invalid connection type" do
      expect { session.connection_type = :bogus }.to raise_error(ArgumentError)
    end

    it "should succeed given a correct connection type" do
      expect { session.connection_type = :wifi }.to_not raise_error
    end
  end

  describe ".connection_types" do
    subject { Hallon::Session.connection_rules }

    it { should be_an Array }
    it { should_not be_empty }
    it { should include :network }
  end

  describe "#connection_rules=" do
    it "should fail given an invalid rule" do
      expect { session.connection_rules = :lawly }.to raise_error
    end

    it "should succeed given correct connection thingy" do
      expect { session.connection_rules = :network, :allow_sync_over_mobile }.to_not raise_error
    end

    it "should combine given rules and feed to libspotify" do
      spotify_api.should_receive(:session_set_connection_rules).with(session.pointer, 5)
      session.connection_rules = :network, :allow_sync_over_mobile
    end
  end

  describe "offline settings readers" do
    let(:session) { mock_session_object }

    describe "#offline_time_left" do
      it "returns the time left until libspotify must go online" do
        session.offline_time_left.should eq 60 * 60 * 24 * 30
      end
    end

    describe "#offline_sync_status" do
      it "returns a hash of offline sync status details" do
        session.offline_sync_status.should eq mock_offline_sync_status_hash
      end

      it "returns an empty hash when offline sync status details are unavailable" do
        spotify_api.should_receive(:offline_sync_get_status).and_return(false)
        session.offline_sync_status.should eq Hash.new
      end
    end

    describe "#offline_playlists_count" do
      it "returns the number of playlists marked for offline synchronization" do
        session.offline_playlists_count.should eq 7
      end
    end

    describe "#offline_tracks_to_sync" do
      it "returns the number of tracks that still need to be synchronized" do
        session.offline_tracks_to_sync.should eq 3
      end
    end
  end

  describe "#offline_bitrate=" do
    it "should not resync unless explicitly told so" do
      spotify_api.should_receive(:session_preferred_offline_bitrate).with(session.pointer, :'96k', false).and_return(:ok)
      session.offline_bitrate = :'96k'
    end

    it "should resync if asked to" do
      spotify_api.should_receive(:session_preferred_offline_bitrate).with(session.pointer, :'96k', true).and_return(:ok)
      session.offline_bitrate = :'96k', :resync
    end

    it "should fail given an invalid value" do
      expect { session.offline_bitrate = :hocum }.to raise_error(ArgumentError)
    end

    it "should succeed given a proper value" do
      expect { session.offline_bitrate = :'96k' }.to_not raise_error
    end
  end


  describe "#starred" do
    let(:starred) { Hallon::Playlist.new("spotify:user:burgestrand:starred") }

    it "should return the sessions (current users) starred playlist" do
      session.login 'burgestrand', 'pass'

      session.should be_logged_in
      session.starred.should eq starred
    end

    it "should return nil if not logged in" do
      session.should_not be_logged_in
      session.starred.should be_nil
    end
  end

  describe "#inbox" do
    let(:inbox) { Hallon::Playlist.new(mock_playlist) }
    let(:session) { mock_session_object }

    it "should return the sessions inbox" do
      session.login 'burgestrand', 'pass'

      session.should be_logged_in
      session.inbox.should eq inbox
    end

    it "should return nil if not logged in" do
      session.should_not be_logged_in
      session.inbox.should be_nil
    end
  end

  describe "#flush_caches" do
    it "flushes the session cache to disk" do
      session.flush_caches # or, actually, it does not crash
    end
  end
end
