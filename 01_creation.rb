require_relative 'setup'

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
  
  
  describe 'instantiating' do
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
        u.name = user_name
        u.posts.build do |post|
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
end