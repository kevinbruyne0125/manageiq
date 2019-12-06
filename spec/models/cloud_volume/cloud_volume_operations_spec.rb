RSpec.describe 'CloudVolume::Operations' do
  let(:disk)         { FactoryBot.create(:disk) }
  let(:ems)          { FactoryBot.create(:ems_vmware) }
  let(:cloud_volume) { FactoryBot.create(:cloud_volume, :ext_management_system => ems) }
  let(:user)         { FactoryBot.create(:user, :userid => 'test') }

  context "queued methods" do
    it "queues an attach task with attach_volume_queue" do
      task_id = cloud_volume.attach_volume_queue(user.userid, ems.id, disk.id)

      expect(MiqTask.find(task_id)).to have_attributes(
        :name   => "attaching Cloud Volume for user #{user.userid}",
        :state  => "Queued",
        :status => "Ok"
      )

      expect(MiqQueue.where(:class_name => cloud_volume.class.name).first).to have_attributes(
        :class_name  => cloud_volume.class.name,
        :method_name => 'attach_volume',
        :role        => 'ems_operations',
        :queue_name  => 'generic',
        :zone        => ems.my_zone,
        :args        => [ems.id, disk.id]
      )
    end

    it "queues a detach task with detach_volume_queue" do
      task_id = cloud_volume.detach_volume_queue(user.userid, ems.id)

      expect(MiqTask.find(task_id)).to have_attributes(
        :name   => "detaching Cloud Volume for user #{user.userid}",
        :state  => "Queued",
        :status => "Ok"
      )

      expect(MiqQueue.where(:class_name => cloud_volume.class.name).first).to have_attributes(
        :class_name  => cloud_volume.class.name,
        :method_name => 'detach_volume',
        :role        => 'ems_operations',
        :queue_name  => 'generic',
        :zone        => ems.my_zone,
        :args        => [ems.id]
      )
    end
  end
end
