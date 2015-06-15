class DialogTab < ActiveRecord::Base
  include DialogMixin
  has_many   :dialog_groups, -> { order(:position) }, :dependent => :destroy
  belongs_to :dialog

  alias_attribute :order, :position

  def to_h
    [self.name.to_sym, self.values_to_h]
  end

  def values_to_h
    result = {}
    ordered_dialog_resources
    result
  end

  def each_dialog_field
    self.dialog_groups.each {|dg| dg.each_dialog_field {|df| yield(df)}}
  end

  def dialog_fields
    self.dialog_groups.collect(&:dialog_fields).flatten!
  end

  def dialog_resources
    self.dialog_groups
  end

end
