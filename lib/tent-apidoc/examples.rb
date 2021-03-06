require 'faker'
require 'fabrication'

class TentApiDoc
  include TentD::Model

  User.current = User.create

  # hack so tentception works
  class TentD::Model::User
    def profile_entity
      nil
    end
  end

  ProfileInfo.create(:type_base => 'https://tent.io/types/info/core',
                     :type_version => '0.1.0',
                     :public => true,
                     :content => {
                       :licenses => ['http://creativecommons.org/licenses/by/3.0/'],
                       :entity => 'https://example.org',
                       :servers => ['https://tent.example.com', 'http://eqt5g4fuenphqinx.onion/']
                     })
  ProfileInfo.create(:type_base => 'https://tent.io/types/info/basic',
                     :type_version => '0.1.0',
                     :public => true,
                     :content => {
                       :name => 'The Tentity',
                       :avatar_url => 'http://example.org/avatar.jpg',
                       :birthdate => '2012-08-23',
                       :location => 'The Internet',
                       :gender => 'Unknown',
                       :bio => Faker::Lorem.sentence
                     })

  example(:get_profile) do
    clients[:base].profile.get
  end

  example(:create_app) do
    clients[:base].app.create(
      :name => "FooApp",
      :description => "Does amazing foos with your data",
      :url => "http://example.com",
      :icon => "http://example.com/icon.png",
      :redirect_uris => ["https://app.example.com/tent/callback"],
      :scopes => {
        :write_profile => "Uses an app profile section to describe foos",
        :read_followings => "Calculates foos based on your followings"
      }).tap {
        clients[:app] = TentClient.new('https://example.com', client_options(App.last))
      }
  end

  example(:app_auth) do
    app = App.first
    auth = app.authorizations.create(
      :scopes => %w(read_posts write_posts import_posts read_profile write_profile read_followers write_followers read_followings write_followings read_groups write_groups read_permissions write_permissions read_apps write_apps follow_ui read_secrets write_secrets),
      :profile_info_types => ['https://tent.io/types/info/basic/v0.1.0'],
      :post_types => ['https://tent.io/types/post/status/v0.1.0', 'https://tent.io/types/post/photo/v0.1.0']
    )
    variables[:app_code] = auth.token_code
    variables[:app_id] = app.public_id
    clients[:app].app.authorization.create(app.public_id, :code => auth.token_code, :token_type => 'mac').tap {
      clients[:auth] = TentClient.new('https://example.com', client_options(AppAuthorization.last))
    }
  end

  example(:create_following) do
    clients[:auth].following.create('https://example.org')
  end

  example(:create_follower) do
    clients[:base].follower.create(
      :entity => 'https://example.org',
      :types => ['all'],
      :notification_path => "notifications/#{Following.last.public_id}",
      :licenses => ['http://creativecommons.org/licenses/by/3.0/']
    ).tap { |res|
      clients[:follower] = TentClient.new('https://example.com', client_options(Follower.last))
      variables[:follower_id] = res.body['id']
    }
  end

  example(:get_follower) do
    clients[:follower].follower.get(variables[:follower_id])
  end

  example(:update_follower) do
    follower = Follower.first(:public_id => variables[:follower_id])
    clients[:follower].follower.update(follower.public_id, follower.attributes.slice(:entity, :licenses).merge(:types => ['https://tent.io/types/post/essay/v0.1.0#full']))
  end

  example(:get_app) do
    clients[:app].app.get(App.last.public_id)
  end

  example(:update_app) do
    clients[:app].app.update(
      App.last.public_id,
      :name => "FooApp",
      :description => "Does amazing foos with your data",
      :url => "http://example.com",
      :icon => "http://example.com/icon.png",
      :redirect_uris => ["https://app.example.com/tent/callback"],
      :scopes => {
        :write_profile => "Uses an app profile section to describe foos",
        :read_followings => "Calculates foos based on your followings",
        :write_following => "Follow new users when you click"
      }
    )
  end

  example(:discovery) do
    clients[:base].http.head('/')
  end

  example(:update_profile) do
    clients[:auth].profile.update(
      'https://tent.io/types/info/basic/v0.1.0',
      :name => 'The Tentity',
      :avatar_url => 'http://example.org/avatar.jpg',
      :birthdate => '2012-08-23',
      :location => 'The Internet',
      :gender => 'Unknown',
      :bio => Faker::Lorem.sentence
    )
  end

  example(:create_post) do
    clients[:auth].post.create(
      :type => 'https://tent.io/types/post/status/v0.1.0',
      :published_at => Time.now.to_i,
      :permissions => { :public => true },
      :licenses => ['http://creativecommons.org/licenses/by/3.0/'],
      :content => {
        :text => "Just landed.",
        :location => {
          :type => 'Point',
          :coordinates => [50.923878, 4.028605]
        }
      }
    ).tap { |res| variables[:post_id] = res.body['id'] }
  end

  example(:create_post_with_attachments) do
    clients[:auth].post.create(
      {
        :type => 'https://tent.io/types/post/photo/v0.1.0',
        :published_at => Time.now.to_i,
        :permissions => { :public => true },
        :licenses => ['http://creativecommons.org/licenses/by/3.0/'],
        :content => {
          :caption => 'Some fake photos'
        }
      },
      :attachments => [
        { :category => 'photos', :filename => 'fake_photo1.jpg', :data => 'Photo 1 data would go here', :type => 'image/jpeg' },
        { :category => 'photos', :filename => 'fake_photo2.jpg', :data => 'Photo 2 data would go here', :type => 'image/jpeg' },
      ]
    )
  end

  example(:get_post_attachment) do
    attachment = PostAttachment.last
    clients[:auth].post.attachment.get(attachment.post.public_id, attachment.name, attachment.type)
  end

  example(:get_followings) do
    clients[:auth].following.list
  end

  example(:get_following) do
    clients[:auth].following.get(Following.last.public_id)
  end

  example(:delete_following) do
    clients[:auth].following.delete(Following.last.public_id)
  end

  example(:get_followers) do
    clients[:auth].follower.list
  end

  example(:get_posts) do
    clients[:auth].post.list
  end

  example(:get_post) do
    clients[:auth].post.get(variables[:post_id])
  end

  example(:follower_get_post) do
    clients[:follower].post.get(variables[:post_id])
  end

  example(:follower_get_posts) do
    clients[:follower].post.list
  end

  example(:delete_follower) do
    clients[:follower].follower.delete(variables[:follower_id])
  end
end
