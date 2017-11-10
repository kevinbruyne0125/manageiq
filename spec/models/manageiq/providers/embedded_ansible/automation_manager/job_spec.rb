describe ManageIQ::Providers::EmbeddedAnsible::AutomationManager::Job do
  let(:job) { FactoryGirl.create(:embedded_ansible_job) }

  it_behaves_like 'ansible job'

  it 'processes retire_now properly' do
    expect(job).to receive(:finish_retirement).once
    job.retire_now
  end

  describe '#raw_stdout_via_worker' do
    before do
      EvmSpecHelper.create_guid_miq_server_zone
      region = MiqRegion.seed
      allow(region).to receive(:role_active?).with("embedded_ansible").and_return(role_enabled)
      allow(MiqRegion).to receive(:my_region).and_return(region)
    end

    context 'when embedded_ansible role is enabled' do
      let(:role_enabled) { true }

      before do
        allow(described_class).to receive(:find).and_return(job)

        allow(MiqTask).to receive(:wait_for_taskid) do
          request = MiqQueue.find_by(:class_name => described_class.name)
          request.update_attributes(:state => MiqQueue::STATE_DEQUEUE)
          request.delivered(*request.deliver)
        end
      end

      it 'gets stdout from the job' do
        expect(job).to receive(:raw_stdout).and_return('A stdout from the job')
        expect(job.raw_stdout_via_worker).to eq('A stdout from the job')
      end

      it 'returns the error message' do
        expect(job).to receive(:raw_stdout).and_throw('Failed to get stdout from the job')
        expect(job.raw_stdout_via_worker).to include('Failed to get stdout from the job')
      end
    end

    context 'when embedded_ansible role is disabled' do
      let(:role_enabled) { false }

      it 'returns an error message' do
        expect(job.raw_stdout_via_worker).to eq('Cannot get standard output of this playbook because the embedded Ansible role is not enabled')
      end
    end
  end
end
