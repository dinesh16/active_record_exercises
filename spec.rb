# SOME SETUP (ignore this part, start below)
require 'active_record'
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

# require 'logger'
# ActiveRecord::Base.logger = Logger.new $stdout
# ActiveSupport::LogSubscriber.colorize_logging = false


ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users do |t|
    t.string :name
  end

  create_table :posts do |t|
    t.string  :name
    t.string  :caption
    t.text    :body
    t.integer :user_id
  end

  create_table :user_favourites_posts do |t| # REMOVE
    t.integer :user_id                       # REMOVE
    t.integer :post_id                       # REMOVE
  end                                        # REMOVE
end

RSpec.configure do |config|
  config.around :each do |spec|
    ActiveRecord::Base.transaction do
      spec.call
      raise ActiveRecord::Rollback
    end
  end
end


# THE SPECS (start here)
describe 'creating active record instances' do
  class UserFavouritesPost < ActiveRecord::Base # REMOVE
    belongs_to :user                            # REMOVE
    belongs_to :post                            # REMOVE
  end                                           # REMOVE

  class User < ActiveRecord::Base
    has_many :posts
    has_many :user_favourites_posts
    has_many :favourite_posts, through: :user_favourites_posts, source: :post # REMOVE

    def fans # REMOVE
      User.where id: posts.joins(:user_favourites_posts).pluck('user_favourites_posts.user_id') # REMOVE
    end # REMOVE
  end

  class Post < ActiveRecord::Base
    belongs_to :user

    has_many   :user_favourites_posts
    has_many   :favourited_by, through: :user_favourites_posts,
                               source:  :user

    scope :with_caption_including,    -> s { where"caption like ?", "%#{s}%" }     # REMOVE
    scope :without_caption_including, -> s { where"caption not like ?", "%#{s}%" } # REMOVE

    validates :name, presence: true # REMOVE
    validates :name, format: { without: /fork|spoon/i, message: "No dinnerware conversation!" }
  end

  let(:user_name) { 'Some user name' }
  let(:post_name) { 'Some post name' }
  let(:caption)   { 'Some caption'   }
  let(:body)      { 'Lorem ipsum dolor sit amet, consectetur adipisicing elit...' }

  def post_has_expected_attributes(post)
    expect(post.name    ).to eq post_name
    expect(post.caption ).to eq caption
    expect(post.body    ).to eq body
  end


  specify "instantiate a post, but don't save it" do
    post = Post.new(name: post_name, caption: caption, body: body) # REMOVE

    post_has_expected_attributes post
    expect(post).to be_a_new_record
  end

  specify 'instantiate a post and save it without using #save' do
    post = Post.create(name: post_name, caption: caption, body: body) # REMOVE

    post_has_expected_attributes post
    expect(post).to be_persisted
  end

  specify 'create a user and build a post without referencing the Post class' do
    user = User.create name: user_name
    post = user.posts.create name: post_name, caption: caption, body: body # REMOVE

    post_has_expected_attributes post
    expect(post.user  ).to eq user
    expect(user.posts ).to eq [post]
    expect(post       ).to be_persisted
  end

  specify 'instantiate a post and build it a user without saving or referencing the Post class' do
    user = User.new name: user_name
    post = user.posts.build name: post_name, caption: caption, body: body # REMOVE

    post_has_expected_attributes post
    expect(post).to be_a_new_record
    expect(user).to be_a_new_record

    user.save!
    expect(post.user   ).to eq user
    expect(user.posts  ).to eq [post]
  end

  specify 'build the post with block style' do
    user = User.new do |u|
      u.name = user_name       # REMOVE
      u.posts.build do |post|  # REMOVE
        post.name = post_name  # REMOVE
        post.caption = caption # REMOVE
        post.body = body       # REMOVE
      end
    end

    expect(user.name       ).to eq user_name
    expect(user            ).to be_a_new_record
    expect(user.posts.size ).to eq 1
    post_has_expected_attributes user.posts.first
  end
end


describe 'with 10 users and 100 posts' do
  class User < ActiveRecord::Base
    has_many :posts
  end

  class Post < ActiveRecord::Base
    belongs_to :user
  end

  before :all do
    10.times do |i|
      User.create! name: "user #{i}" do |user|
        10.times do |j|
          post_number = i * 10 + j
          user.posts.build name: "post #{post_number}", caption: "caption #{post_number}", body: "body #{post_number}"
        end
      end
    end
  end

  after :all do
    User.delete_all
    Post.delete_all
  end

  specify 'count the users and posts' do
    user_count = User.count
    post_count = Post.count

    expect(user_count).to eq 10
    expect(post_count).to eq 100
  end

  specify 'find all the users' do
    users = User.all # REMOVE
    expect(users.pluck :id).to eq (1..10).to_a
  end

  specify 'find all the posts' do
    posts = Post.all # REMOVE
    expect(posts.pluck :id).to eq (1..100).to_a
  end

  specify 'find a specific user' do
    user8 = User.find 8 # REMOVE
    expect(user8.id).to eq 8
  end

  specify 'the first 5 posts (limit)' do
    first5 = Post.limit(5) # REMOVE
    expect(first5.pluck :id).to eq (1..5).to_a
  end

  specify 'the second 5 posts (limit, offset)' do
    second5 = Post.offset(5).limit(5) # REMOVE
    expect(second5.pluck :id).to eq (6..10).to_a
  end

  specify 'the 5 newest posts (limit, order)' do
    last5 = Post.order('id desc').limit(5) # REMOVE
    expect(last5.pluck :id).to eq (96..100).to_a.reverse
  end

  specify 'users where the name is in "user 2", "user 3", "user 5", "user 7" (where)' do
    usernames   = ['user 2', 'user 3', 'user 5', 'user 7']
    prime_users = User.where name: usernames # REMOVE
    expect(prime_users.pluck :name).to eq usernames
  end

  specify 'count the number of posts whose name has a 1 in it (where, count)' do
    post_count = Post.where("name like '%1%'").count # REMOVE
    expect(post_count).to eq 19
  end

  specify 'the post whose name is "post 45" (where, first)' do
    post = Post.where(name: 'post 45').first
    expect(post.name).to eq 'post 45'
  end

  specify "user5's first three posts, without referencing Post (association, limit)" do
    user5 = User.find 5
    posts = user5.posts.limit(3)
    expect(posts.pluck :id).to eq [41, 42, 43]
  end

  specify "user5's three most recent posts (most recent first), without referencing Post (association, limit, order)" do
    user5 = User.find 5
    posts = user5.posts.limit(3).order('id desc')
    expect(posts.pluck :id).to eq [50, 49, 48]
  end

  specify "the first three users and their most recent post name (limit, includes)" do
    users_and_posts = User.limit(3).includes(:posts).map { |u| [u.name, u.posts.take(2).map(&:name)] }
    expect(users_and_posts).to eq [
      ['user 0', ['post 0',  'post 1']],
      ['user 1', ['post 10', 'post 11']],
      ['user 2', ['post 20', 'post 21']],
    ]
  end

  # you'll need to go back up and implement this
  # REMEMBER: USE "?" FOR VALUES TO INTERPOLATE INTO THE QUERY
  describe 'Post.with_caption_including' do
    it 'is implemented' do
      # nothing for you to do here,
      # we're checking that with_caption_including is implemented correctly
      posts = Post.with_caption_including('2')
      expect(posts.pluck :id).to eq [3, 13, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 33, 43, 53, 63, 73, 83, 93]
    end

    specify 'second 5 posts with caption including "2"' do
      posts = Post.with_caption_including('2').offset(5).limit(5) # REMOVE
      expect(posts.pluck :id).to eq [24, 25, 26, 27, 28]
    end

    specify "a user's posts that contain the caption '3', using with_caption_including, without referencing the Post constant" do
      user1  = User.find 1
      user2  = User.find 2
      posts1 = user1.posts.with_caption_including('3') # REMOVE
      posts2 = user2.posts.with_caption_including('3') # REMOVE
      expect(posts1.pluck :caption).to eq ['caption 3']
      expect(posts2.pluck :caption).to eq ['caption 13']
    end
  end

  describe 'Post.without_caption_including' do
    it 'is implemented' do
      # nothing for you to do here,
      # we're checking that with_caption_including is implemented correctly
      posts = User.first.posts.without_caption_including('2')
      expect(posts.pluck :id).to eq [1, 2, 4, 5, 6, 7, 8, 9, 10]
    end

    specify 'posts with caption including "1", without caption including "2"' do
      posts = Post.with_caption_including('1').without_caption_including('2') # REMOVE
      expect(posts.pluck :id).to eq [2, 11, 12, 14, 15, 16, 17, 18, 19, 20, 32, 42, 52, 62, 72, 82, 92]
    end
  end

  describe 'favouriting posts' do
    let(:author1) { User.find 1 }

    let(:reader1) { User.find 2 }
    let(:reader2) { User.find 3 }
    let(:reader3) { User.find 4 }

    specify 'a post can find the users who favourited it' do
      # You are going to need to edit the schema and the classes
      # to make this work
      # http://guides.rubyonrails.org/association_basics.html
      post = Post.first
      post.favourited_by << reader1
      post.favourited_by << reader3
      expect(post.reload.favourited_by).to eq [reader1, reader3]
    end

    specify 'a user can find their favourite posts' do
      post1 = Post.first
      post2 = Post.last
      reader1.favourite_posts << post1
      reader1.favourite_posts << post2
      expect(reader1.favourite_posts).to eq [post1, post2]
    end

    specify "can find an author's fans: who has favourited thier posts" do
      author1.posts.first.favourited_by << reader1
      author1.posts.last.favourited_by  << reader2
      expect(author1.fans).to eq [reader1, reader2]
    end
  end

  describe 'validations' do
    specify 'a post is invalid if its name is blank' do
      post = Post.new(name: 'name', caption: 'caption', body: 'body', user: User.find(1))
      expect(post).to be_valid

      post = Post.new(name: nil, caption: 'caption', body: 'body', user: User.find(1))
      expect(post).to_not be_valid

      post = Post.new(name: '', caption: 'caption', body: 'body', user: User.find(1))
      expect(post).to_not be_valid
    end

    specify 'a post is invalid if its name mentions "fork"' do
      post = Post.new(name: 'name', caption: 'caption', body: 'body', user: User.find(1))
      expect(post).to be_valid

      post.name = 'Eat salad with a fork!'
      expect(post).to_not be_valid

      post.name = 'EAT SALAD WITH A FORK!'
      expect(post).to_not be_valid
      expect(post.errors[:name]).to eq ['No dinnerware conversation!']
    end

    specify 'use a transaction to prevent a post from saving', t:true do
      initial_count = Post.count
      expect {
        Post.transaction do
          Post.create!(name: 'name', caption: 'caption', body: 'body', user: User.find(1))
          expect(Post.count).to eq initial_count+1
          Post.create!(name: 'spoon', caption: 'caption', body: 'body', user: User.find(1))
        end
      }.to raise_error
      expect(Post.count).to eq initial_count
    end
  end
end
