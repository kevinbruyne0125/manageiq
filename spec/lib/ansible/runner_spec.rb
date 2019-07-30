describe Ansible::Runner do
  let(:uuid)       { "201ac780-7bf4-0136-3b9e-54e1ad8b3cf4" }
  let(:env_vars)   { {"ENV1" => "VAL1", "ENV2" => "VAL2"} }
  let(:extra_vars) { {"id" => uuid} }
  let(:tags)       { "tag" }
  let(:result)     { AwesomeSpawn::CommandResult.new("ansible-runner", "output", "", "0") }

  describe ".run" do
    let(:playbook) { "/path/to/my/playbook" }
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(playbook).and_return(true)
    end

    it "calls run and writes the required files" do
      expect(AwesomeSpawn).to receive(:run) do |command, options|
        expect(command).to eq("ansible-runner")
        expect(options[:env]).to eq(env_vars)

        method, dir, json, args = options[:params]

        expect(method).to eq("run")
        expect(json).to   eq(:json)
        expect(args).to   eq(:ident => "result", :playbook => "playbook", :project_dir => "/path/to/my")

        hosts = File.read(File.join(dir, "inventory", "hosts"))
        expect(hosts).to eq("localhost")

        extravars = JSON.parse(File.read(File.join(dir, "env", "extravars")))
        expect(extravars).to eq("id" => uuid, "ansible_connection" => "local")

        expect(File.exist?(File.join(dir, "env", "cmdline"))).to be_falsey
      end.and_return(result)

      described_class.run(env_vars, extra_vars, playbook)
    end

    it "calls launch with expected tag" do
      expect(AwesomeSpawn).to receive(:run) do |command, options|
        expect(command).to eq("ansible-runner")
        expect(options[:env]).to eq(env_vars)

        method, dir, json, args = options[:params]

        expect(method).to eq("run")
        expect(json).to   eq(:json)
        expect(args).to   eq(:ident => "result", :playbook => "playbook", :project_dir => "/path/to/my")

        hosts = File.read(File.join(dir, "inventory", "hosts"))
        expect(hosts).to eq("localhost")

        extravars = JSON.parse(File.read(File.join(dir, "env", "extravars")))
        expect(extravars).to eq("id" => uuid, "ansible_connection" => "local")

        cmdline = File.read(File.join(dir, "env", "cmdline"))
        expect(cmdline).to eq("--tags #{tags}")
      end.and_return(result)

      described_class.run(env_vars, extra_vars, playbook, :tags => tags)
    end

    it "calls run with the correct verbosity" do
      expect(AwesomeSpawn).to receive(:run) do |command, options|
        expect(command).to eq("ansible-runner")

        _method, _dir, _json, args = options[:params]
        expect(args).to eq(:ident => "result", :playbook => "playbook", :project_dir => "/path/to/my", "-vvvvv" => nil)
      end.and_return(result)

      described_class.run(env_vars, extra_vars, playbook, :verbosity => 6)
    end

    it "calls run with become options" do
      expect(AwesomeSpawn).to receive(:run) do |command, options|
        expect(command).to eq("ansible-runner")

        _method, dir, _json, _args = options[:params]
        cmdline = File.read(File.join(dir, "env", "cmdline"))

        expect(cmdline).to eq("--become --ask-become-pass")
      end.and_return(result)

      described_class.run(env_vars, extra_vars, playbook, :become_enabled => true)
    end

    context "with special characters" do
      let(:env_vars)   { {"ENV1" => "pa$%w0rd!'"} }
      let(:extra_vars) { {"name" => "john's server"} }

      it "calls launch with expected arguments" do
        expect(AwesomeSpawn).to receive(:run) do |command, options|
          expect(command).to eq("ansible-runner")
          expect(options[:env]).to eq(env_vars)

          method, dir, json, args = options[:params]

          expect(method).to eq("run")
          expect(json).to   eq(:json)
          expect(args).to   eq(:ident => "result", :playbook => "playbook", :project_dir => "/path/to/my")

          hosts = File.read(File.join(dir, "inventory", "hosts"))
          expect(hosts).to eq("localhost")

          extravars = JSON.parse(File.read(File.join(dir, "env", "extravars")))
          expect(extravars).to eq("name" => "john's server", "ansible_connection" => "local")
        end.and_return(result)

        described_class.run(env_vars, extra_vars, playbook)
      end
    end
  end

  describe ".run_async" do
    let(:playbook) { "/path/to/my/playbook" }
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(playbook).and_return(true)
    end

    it "calls ansible-runner with start" do
      expect(AwesomeSpawn).to receive(:run) do |command, options|
        expect(command).to eq("ansible-runner")
        expect(options[:env]).to eq(env_vars)

        method, dir, json, args = options[:params]

        expect(method).to eq("start")
        expect(json).to   eq(:json)
        expect(args).to   eq(:ident => "result", :playbook => "playbook", :project_dir => "/path/to/my")

        hosts = File.read(File.join(dir, "inventory", "hosts"))
        expect(hosts).to eq("localhost")

        extravars = JSON.parse(File.read(File.join(dir, "env", "extravars")))
        expect(extravars).to eq("id" => uuid, "ansible_connection" => "local")

        expect(File.exist?(File.join(dir, "env", "cmdline"))).to be_falsey
      end.and_return(result)

      runner_result = described_class.run_async(env_vars, extra_vars, playbook)
      expect(runner_result).kind_of?(Ansible::Runner::ResponseAsync)
    end
  end

  describe ".run_queue" do
    let(:playbook) { "/path/to/my/playbook" }
    let(:zone)     { FactoryBot.create(:zone) }
    let(:user)     { FactoryBot.create(:user) }

    it "queues Ansible::Runner.run in the right zone" do
      described_class.run_queue(env_vars, extra_vars, playbook, user.name, :zone => zone.name)

      expect(MiqQueue.count).to eq(1)
      expect(MiqQueue.first.zone).to eq(zone.name)
    end
  end

  describe ".run_role" do
    let(:role_name) { "my-custom-role" }
    let(:role_path) { "/path/to/my/roles" }
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(role_path).and_return(true)
    end

    it "runs ansible-runner with the role" do
      expect(AwesomeSpawn).to receive(:run) do |command, options|
        expect(command).to eq("ansible-runner")
        expect(options[:env]).to eq(env_vars)

        method, dir, json, args = options[:params]

        expect(method).to eq("run")
        expect(json).to   eq(:json)
        expect(args).to   eq(:ident => "result", :role => role_name, :roles_path => role_path, :role_skip_facts => nil)

        hosts = File.read(File.join(dir, "inventory", "hosts"))
        expect(hosts).to eq("localhost")

        extravars = JSON.parse(File.read(File.join(dir, "env", "extravars")))
        expect(extravars).to eq("id" => uuid, "ansible_connection" => "local")

        expect(File.exist?(File.join(dir, "env", "cmdline"))).to be_falsey
      end.and_return(result)

      described_class.run_role(env_vars, extra_vars, role_name, :roles_path => role_path)
    end

    it "runs ansible-runner with role and tag" do
      expect(AwesomeSpawn).to receive(:run) do |command, options|
        expect(command).to eq("ansible-runner")
        expect(options[:env]).to eq(env_vars)

        method, dir, json, args = options[:params]

        expect(method).to eq("run")
        expect(json).to   eq(:json)
        expect(args).to   eq(:ident => "result", :role => role_name, :roles_path => role_path, :role_skip_facts => nil)

        hosts = File.read(File.join(dir, "inventory", "hosts"))
        expect(hosts).to eq("localhost")

        extravars = JSON.parse(File.read(File.join(dir, "env", "extravars")))
        expect(extravars).to eq("id" => uuid, "ansible_connection" => "local")

        cmdline = File.read(File.join(dir, "env", "cmdline"))
        expect(cmdline).to eq("--tags #{tags}")
      end.and_return(result)

      described_class.run_role(env_vars, extra_vars, role_name, :roles_path => role_path, :tags => tags)
    end
  end

  describe ".run_role_async" do
    let(:role_name) { "my-custom-role" }
    let(:role_path) { "/path/to/my/roles" }
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(role_path).and_return(true)
    end

    it "runs ansible-runner with the role" do
      expect(AwesomeSpawn).to receive(:run) do |command, options|
        expect(command).to eq("ansible-runner")
        expect(options[:env]).to eq(env_vars)

        method, dir, json, args = options[:params]

        expect(method).to eq("start")
        expect(json).to   eq(:json)
        expect(args).to   eq(:ident => "result", :role => role_name, :roles_path => role_path, :role_skip_facts => nil)

        hosts = File.read(File.join(dir, "inventory", "hosts"))
        expect(hosts).to eq("localhost")

        extravars = JSON.parse(File.read(File.join(dir, "env", "extravars")))
        expect(extravars).to eq("id" => uuid, "ansible_connection" => "local")

        expect(File.exist?(File.join(dir, "env", "cmdline"))).to be_falsey
      end.and_return(result)

      described_class.run_role_async(env_vars, extra_vars, role_name, :roles_path => role_path)
    end
  end

  describe ".run_role_queue" do
    let(:role_name) { "my-custom-role" }
    let(:role_path) { "/path/to/my/roles" }
    let(:zone)      { FactoryBot.create(:zone) }
    let(:user)      { FactoryBot.create(:user) }

    it "queues Ansible::Runner.run in the right zone" do
      queue_args = {:zone => zone.name}
      described_class.run_role_queue(env_vars, extra_vars, role_name, user.name, queue_args, :roles_path => role_path)

      expect(MiqQueue.count).to eq(1)
      expect(MiqQueue.first.zone).to eq(zone.name)
    end
  end
end
