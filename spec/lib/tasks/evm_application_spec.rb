require Rails.root.join("lib", "tasks", "evm_application")

describe EvmApplication do
  context ".server_state" do
    it "with a valid status" do
      EvmSpecHelper.create_guid_miq_server_zone

      expect(EvmApplication.server_state).to eq("started")
    end

    it "without a database connection" do
      allow(MiqServer).to receive(:my_server).and_raise("`initialize': could not connect to server: Connection refused (PGError)")

      expect(EvmApplication.server_state).to eq(:no_db)
    end
  end

  context ".update_start" do
    it "was running" do
      expect(FileUtils).to receive(:mkdir_p).once
      expect(File).to receive(:file?).once.and_return(true)
      expect(File).to receive(:write).once
      expect(FileUtils).to receive(:rm_f).once

      described_class.update_start
    end

    it "was not running" do
      expect(FileUtils).to receive(:mkdir_p).once
      expect(FileUtils).to receive(:rm_f).once

      described_class.update_start
    end
  end

  context ".update_stop" do
    it "was running" do
      EvmSpecHelper.create_guid_miq_server_zone
      expect(FileUtils).to receive(:mkdir_p)
      expect(File).to receive(:write)
      expect(EvmApplication).to receive(:stop)

      described_class.update_stop
    end

    it "was not running" do
      _, server, = EvmSpecHelper.create_guid_miq_server_zone
      server.update_attribute(:status, "stopped")

      described_class.update_stop
    end
  end
end
