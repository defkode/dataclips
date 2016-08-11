class AddPasswordToInsights < ActiveRecord::Migration
  def change
    add_column :dataclips_insights, :basic_auth_credentials, :string
  end
end
