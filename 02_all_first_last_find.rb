require_relative 'setup'

describe 'creating active record instances' do
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
end








