class RemoveQueryAndSchemaColumns < ActiveRecord::Migration
  def change
    remove_column :dataclips_insights, :query
    remove_column :dataclips_insights, :schema

    add_column :dataclips_insights, :schema, :string

    add_index :dataclips_insights, :schema
  end
end
