class RemoveSystemAddSourceToMiqAeNamespace < ActiveRecord::Migration[5.0]
  class MiqAeNamespace < ActiveRecord::Base; end

  def up
    say_with_time('Migrating System attribute to Source in MiqAeNamespace') do
      add_column :miq_ae_namespaces, :source, :string

      MiqAeNamespace.where('parent_id IS NULL').each do |obj|
        source = if obj.name == 'ManageIQ'
                   'system'
                 else
                   obj.system ? 'user_locked' : 'user'
                 end
        obj.update_attributes!(:source => source)
      end

      remove_column :miq_ae_namespaces, :system
    end
  end

  def down
    say_with_time('Migrating Source attribute to System in MiqAeNamespace') do
      add_column :miq_ae_namespaces, :system, :boolean
      MiqAeNamespace.where('parent_id IS NULL').each do |obj|
        system = (obj.source == 'system' || obj.source == 'user_locked') ? true : false
        obj.update_attributes!(:system => system)
      end
      remove_column :miq_ae_namespaces, :source
    end
  end
end
