describe TaskHelpers::Exports::Roles do
  let(:role_test_export) do
    [{"name"                => "Test Role",
      "read_only"           => false,
      "settings"            => nil,
      "feature_identifiers" => ["about"]}]
  end

  let(:role_super_export) do
    [{"name"                => "EvmRole-super_administrator",
      "read_only"           => true,
      "settings"            => nil,
      "feature_identifiers" => []}]
  end

  let(:export_dir) do
    Dir.mktmpdir('miq_exp_dir')
  end

  before do
    FactoryGirl.create(:miq_user_role, :name => "Test Role", :features => "about")
    FactoryGirl.create(:miq_user_role, :role => "super_administrator")
  end

  after do
    FileUtils.remove_entry export_dir
  end

  it 'exports user roles to a given directory' do
    TaskHelpers::Exports::Roles.new.export(:directory => export_dir)
    file_contents = File.read("#{export_dir}/Test_Role.yaml")
    expect(YAML.load(file_contents)).to eq(role_test_export)
    expect(Dir[File.join(export_dir, '**', '*')].count { |file| File.file?(file) }).to eq(1)
  end

  it 'exports all roles to a given directory' do
    TaskHelpers::Exports::Roles.new.export(:directory => export_dir, :all => true)
    file_contents = File.read("#{export_dir}/Test_Role.yaml")
    file_contents2 = File.read("#{export_dir}/EvmRole-super_administrator.yaml")
    expect(YAML.load(file_contents)).to eq(role_test_export)
    expect(YAML.load(file_contents2)).to eq(role_super_export)
    expect(Dir[File.join(export_dir, '**', '*')].count { |file| File.file?(file) }).to eq(2)
  end
end
