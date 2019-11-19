describe MiqWorkerType do
  describe ".seed" do
    before { described_class.seed }

    it "doesn't create a row for excluded classes" do
      expect(described_class.count).to be > 0
      expect(described_class.pluck(:worker_type)).not_to include(*described_class::EXCLUDED_CLASS_NAMES)
    end

    it "correctly creates records for workers" do
      generic_worker = described_class.find_by(:worker_type => "MiqGenericWorker")
      ui_worker      = described_class.find_by(:worker_type => "MiqUiWorker")

      expect(generic_worker.bundler_groups).to match_array(MiqGenericWorker.bundler_groups)
      expect(generic_worker.kill_priority).to eq(MiqGenericWorker.kill_priority)

      expect(ui_worker.bundler_groups).to match_array(MiqUiWorker.bundler_groups)
      expect(ui_worker.kill_priority).to eq(MiqUiWorker.kill_priority)
    end
  end
end
