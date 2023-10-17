require "active_record"
require "sqlite3"

require_relative "understand_rails_async_db_queries_setup/async_query_loader"

RSpec.describe "POST: Understand Rails async database queries by reimplementing them in 51 lines of simple Ruby" do
  let(:user_klass) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Base.connection.create_table :users, force: true do |t|
      t.string :name
    end

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = :users
    end

    klass.create!(name: "Tester A")
    klass.create!(name: "Tester B")
    klass
  end

  let(:async_query_loader) { AsyncQueryLoader.new }

  it "works when loading the query through our async loader" do
    expect(async_query_loader.run_async(user_klass.limit(2)).result.map { |record| record["name"] }).to eq ["Tester A", "Tester B"]
  end
end
