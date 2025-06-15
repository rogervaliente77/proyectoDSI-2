class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :full_name
      t.string :jwt_token
      t.string :email
      t.string :phone_number
      t.string :password_digest
      t.boolean :is_valid
      t.string :session_token_id
      t.integer :otp_code
      t.boolean :is_admin

      t.timestamps
    end
    add_index :users, :email
  end
end
