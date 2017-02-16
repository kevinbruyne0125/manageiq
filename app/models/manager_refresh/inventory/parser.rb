class ManagerRefresh::Inventory::Parser
  attr_accessor :collector
  attr_accessor :persister

  def parse
    raise NotImplementedError, _("must be implemented in a subclass")
  end
end
