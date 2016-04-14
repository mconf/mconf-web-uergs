class AddOauth2EnabledToSite < ActiveRecord::Migration
  def change
    add_column :sites, :oauth2_enabled, :boolean
  end
end
