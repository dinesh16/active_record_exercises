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