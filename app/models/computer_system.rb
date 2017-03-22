class ComputerSystem < ApplicationRecord
  belongs_to :managed_entity, :polymorphic => true

  has_one :operating_system, :dependent => :destroy
  has_one :hardware, :dependent => :destroy
  has_one :physical_server, :dependent => :destroy
end
