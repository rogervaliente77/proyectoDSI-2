class CreateUserSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_sessions do |t|
      t.string :session_token
      t.datetime :expiration_time
      t.references :user, null: false, foreign_key: true
      t.string :user_email

      t.timestamps
    end
  end
end
