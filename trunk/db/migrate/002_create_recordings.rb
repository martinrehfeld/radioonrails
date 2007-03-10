class CreateRecordings < ActiveRecord::Migration
  def self.up
    create_table :recordings do |t|
      t.column :title, :string
      t.column :starttime, :timestamp
      t.column :duration, :integer
      t.column :station_id, :integer
      t.column :recorder, :text
      t.column :state, :string
    end
  end

  def self.down
    drop_table :recordings
  end
end
