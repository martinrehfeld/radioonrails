class CreateStations < ActiveRecord::Migration
  def self.up
    create_table :stations do |t|
      t.column :name, :string
      t.column :logo, :string
      t.column :stream_url, :string
      t.column :epg_url, :string
    end
  end

  def self.down
    drop_table :stations
  end
end
