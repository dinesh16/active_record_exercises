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