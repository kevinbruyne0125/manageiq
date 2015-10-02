class PxeImage < ActiveRecord::Base
  belongs_to :pxe_image_type
  belongs_to :pxe_server
  belongs_to :pxe_menu

  has_many :customization_templates, :through => :pxe_image_type

  include ReportableMixin

  before_validation do
    if self.default_for_windows_changed? && self.default_for_windows?
      pxe_server.pxe_images.where(:default_for_windows => true).update_all(:default_for_windows => false)
    end
    true
  end

  def self.model_suffix
    name[8..-1]
  end

  def self.corresponding_menu
    @corresponding_menu ||= "PxeMenu#{model_suffix}".constantize
  end

  def build_pxe_contents(ks_access_path, ks_device)
    options = kernel_options.to_s.split(" ")
    update_pxe_content_option(options, "ks=",       ks_access_path)
    update_pxe_content_option(options, "ksdevice=", ks_device)

    options.compact.join(" ").strip
  end

  def parsed_contents=(contents)
    name = contents[:label]
    self.name           = name
    self.description    = (contents[:menu_label] || name)
    self.kernel         = contents[:kernel]
    self.kernel_options = contents[:kernel_options]
    self.initrd         = contents[:initrd]
  end

  def self.pxe_server_filepath(pxe_server, mac_address)
    File.join(pxe_server.pxe_directory, pxe_server_filename(mac_address))
  end

  def create_files_on_server(pxe_server, mac_address, customization_template = nil)
    filepath = self.class.pxe_server_filepath(pxe_server, mac_address)

    if customization_template.kind_of?(CustomizationTemplateKickstart)
      ks_settings = CustomizationTemplateKickstart.ks_settings_for_pxe_image(pxe_server, self, mac_address)
    else
      ks_settings = {}
    end
    contents = build_pxe_contents(*ks_settings.values_at(:ks_access_path, :ks_device))

    pxe_server.write_file(filepath, contents)
  end

  def delete_files_on_server(pxe_server, mac_address)
    filepath = self.class.pxe_server_filepath(pxe_server, mac_address)
    pxe_server.delete_file(filepath)
  end

  private

  def update_pxe_content_option(options, key, value)
    index = options.index { |i| i.start_with?(key) }
    index = options.length if index.nil?
    value.blank? ? options.delete_at(index) : options[index] = "#{key}#{value}"
  end
end
