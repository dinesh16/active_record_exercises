# SOME SETUP (ignore this part, start below)
require 'active_record'
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

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
  class User < ActiveRecord::Base
    has_many :posts
  end

  class Post < ActiveRecord::Base
    belongs_to :user
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
      User.create name: "user #{i}" do |user|
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

  specify 'the last 5 users (limit, order)' do
    last5 = Post.order('id desc').limit(5) # REMOVE
    expect(last5.pluck :id).to eq (96..100).to_a.reverse
  end

  specify 'users where the name is in user2, user3, user5, user7' do
    usernames   = ['user 2', 'user 3', 'user 5', 'user 7']
    prime_users = User.where name: usernames # REMOVE
    expect(prime_users.pluck :name).to eq usernames
  end

  specify 'count the number of posts whose name has a 1 in it' do
    post_count = Post.where("name like '%1%'")
                     .count # REMOVE
    expect(post_count).to eq 19
  end

end
