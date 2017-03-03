class MiqExpression::Tag < MiqExpression::Field
  REGEX = /
(?<model_name>([[:alnum:]]*(::)?)+)
\.(?<associations>([a-z_]+\.)*)
(?<namespace>\bmanaged|user_tag\b)
-(?<column>[a-z]+[_[:alnum:]]+)
/x

  MANAGED_NAMESPACE      = 'managed'.freeze
  USER_NAMESPACE         = 'user'.freeze

  attr_reader :namespace

  def initialize(model, associations, column, managed = true)
    super(model, associations, column)
    @namespace = "/#{managed ? MANAGED_NAMESPACE : USER_NAMESPACE}/#{column}"
  end

  def contains(value)
    ids = model.find_tagged_with(:any => value, :ns => namespace).pluck(:id)
    model.arel_attribute(:id).in(ids)
  end

  def numeric?
    false
  end

  def column_type
    :string
  end

  def sub_type
    column_type
  end

  def attribute_supported_by_sql?
    false
  end
end
