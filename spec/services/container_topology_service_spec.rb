require "spec_helper"

describe ContainerTopologyService do

  let(:container_topology_service) { described_class.new(nil) }

  describe "#build_kinds" do
    it "creates the expected number of entity types" do
      ems_kube = FactoryGirl.create(:ems_kubernetes, :name => "ems_kube")
      container_topology_service.stub(:retrieve_providers).and_return([ems_kube ])
      expect(container_topology_service.build_kinds.keys).to match_array([:Container, :Host, :Kubernetes, :Node, :Pod, :Replicator, :Route, :Service, :VM])
    end
  end

  describe "#build_link" do
    it "creates link between source to target" do
      expect(container_topology_service.build_link("95e49048-3e00-11e5-a0d2-18037327aaeb", "96c35f65-3e00-11e5-a0d2-18037327aaeb")).to eq(:source => "95e49048-3e00-11e5-a0d2-18037327aaeb", :target => "96c35f65-3e00-11e5-a0d2-18037327aaeb")
    end
  end

  describe "#build_topology" do
    it "topology contains only the expected keys" do
      expect(container_topology_service.build_topology.keys).to match_array([:items, :kinds, :relations])
    end

    let(:container) { Container.create(:name => "ruby-example", :ems_ref => "3572afee-3a41-11e5-a79a-001a4a231290_ruby-helloworld-database_openshift\n/mysql-55-centos7:latest", :state => 'running') }
    let(:container_condition) { ContainerCondition.create(:name => 'Ready', :status => 'True') }
    let(:container_def) { ContainerDefinition.create(:name => "ruby-example", :ems_ref => 'b6976f84-5184-11e5-950e-001a4a231290_ruby-helloworld_172.30.194.30:5000/test/origin-ruby-sample@sha256:0cd076c9beedb3b1f5cf3ba43da6b749038ae03f5886b10438556e36ec2a0dd9', :container => container) }
    let(:container_node) { ContainerNode.create(:ext_management_system => ems_kube, :name => "127.0.0.1", :ems_ref => "905c90ba-3e00-11e5-a0d2-18037327aaeb", :container_conditions => [container_condition], :lives_on => vm_rhev) }
    let(:ems_kube) { FactoryGirl.create(:ems_kubernetes, :name => "ems_kube") }
    let(:ems_rhev) { FactoryGirl.create(:ems_redhat, :name => "ems_rhev") }
    let(:vm_rhev) { FactoryGirl.create(:vm_redhat, :name => "vm1", :uid_ems => "558d9a08-7b13-11e5-8546-129aa6621998", :ext_management_system => ems_rhev) }

    it "topology contains the expected structure and content" do
      # vm and host test cross provider correlation to infra provider
      hardware = FactoryGirl.create(:hardware, :cpu_sockets => 2, :cpu_cores_per_socket => 4, :cpu_total_cores => 8)
      host = FactoryGirl.create(:host, :name => "host1",
                                :uid_ems => "abcd9a08-7b13-11e5-8546-129aa6621999",
                                :ext_management_system => ems_rhev,
                                :hardware => hardware)
      vm_rhev.update_attributes(:host => host, :raw_power_state => "up")

      container_topology_service.stub(:retrieve_providers).and_return([ems_kube])
      container_replicator = ContainerReplicator.create(:ext_management_system => ems_kube,
                                                        :ems_ref => "8f8ca74c-3a41-11e5-a79a-001a4a231290",
                                                        :name => "replicator1")
      container_route = ContainerRoute.create(:ext_management_system => ems_kube,
                                              :ems_ref => "ab5za74c-3a41-11e5-a79a-001a4a231290",
                                              :name => "route-edge")
      container_group = ContainerGroup.create(:ext_management_system => ems_kube,
                                              :container_node => container_node, :container_replicator => container_replicator,
                                              :name => "myPod", :ems_ref => "96c35ccd-3e00-11e5-a0d2-18037327aaeb",
                                              :phase => "Running", :container_definitions => [container_def])
      container_service = ContainerService.create(:ext_management_system => ems_kube, :container_groups => [container_group],
                                                  :ems_ref => "95e49048-3e00-11e5-a0d2-18037327aaeb",
                                                  :name => "service1", :container_routes => [container_route])

      topology = container_topology_service.build_topology

      topology[:items].size.should eql 9
      topology[:relations].size.should eql 8

      topology[:items].key? "905c90ba-3e00-11e5-a0d2-18037327aaeb"

      topology[:items][ems_kube.id.to_s].should eql(:id => ems_kube.id.to_s, :name => "ems_kube", :status => "Unknown", :kind => "Kubernetes", :miq_id => ems_kube.id)

      topology[:items]["905c90ba-3e00-11e5-a0d2-18037327aaeb"].should eql(:id => "905c90ba-3e00-11e5-a0d2-18037327aaeb", :name => "127.0.0.1",
                                                                          :status => "Ready", :kind => "Node", :miq_id => container_node.id)
      topology[:items]["8f8ca74c-3a41-11e5-a79a-001a4a231290"].should eql(:id => "8f8ca74c-3a41-11e5-a79a-001a4a231290", :name => "replicator1",
                                                                          :status => "OK", :kind => "Replicator", :miq_id => container_replicator.id)
      topology[:items]["95e49048-3e00-11e5-a0d2-18037327aaeb"].should eql(:id => "95e49048-3e00-11e5-a0d2-18037327aaeb", :name => "service1",
                                                                          :status => "Unknown", :kind => "Service", :miq_id => container_service.id)
      topology[:items]["96c35ccd-3e00-11e5-a0d2-18037327aaeb"].should eql(:id => "96c35ccd-3e00-11e5-a0d2-18037327aaeb", :name => "myPod",
                                                                          :status => "Running", :kind => "Pod", :miq_id => container_group.id)
      topology[:items]["ab5za74c-3a41-11e5-a79a-001a4a231290"].should eql(:id => "ab5za74c-3a41-11e5-a79a-001a4a231290", :name => "route-edge",
                                                                          :status => "Unknown", :kind => "Route", :miq_id => container_route.id)
      topology[:items]["3572afee-3a41-11e5-a79a-001a4a231290_ruby-helloworld-database_openshift\n/mysql-55-centos7:latest"].should eql(:id => "3572afee-3a41-11e5-a79a-001a4a231290_ruby-helloworld-database_openshift\n/mysql-55-centos7:latest", :name => "ruby-example", :status => "Running", :kind => "Container",  :miq_id => container.id)

      topology[:items]["558d9a08-7b13-11e5-8546-129aa6621998"].should eql(:id => "558d9a08-7b13-11e5-8546-129aa6621998",
                                                                          :name => "vm1", :status => "On", :kind => "VM",
                                                                          :miq_id => vm_rhev.id, :provider => "ems_rhev")
      topology[:items]["abcd9a08-7b13-11e5-8546-129aa6621999"].should eql(:id => "abcd9a08-7b13-11e5-8546-129aa6621999",
                                                                          :name => "host1", :status => "On", :kind => "Host",
                                                                          :miq_id => host.id, :provider => "ems_rhev")


      topology[:relations].should include(:source => "96c35ccd-3e00-11e5-a0d2-18037327aaeb",
                                          :target => "8f8ca74c-3a41-11e5-a79a-001a4a231290")
      topology[:relations].should include(:source => "95e49048-3e00-11e5-a0d2-18037327aaeb",
                                          :target => "ab5za74c-3a41-11e5-a79a-001a4a231290")
      # cross provider correlations
      topology[:relations].should include(:source => "558d9a08-7b13-11e5-8546-129aa6621998",
                                          :target => "abcd9a08-7b13-11e5-8546-129aa6621999")
      topology[:relations].should include(:source => "905c90ba-3e00-11e5-a0d2-18037327aaeb",
                                          :target => "558d9a08-7b13-11e5-8546-129aa6621998")

      topology[:relations].should include(:source=> ems_kube.id.to_s, :target=>"905c90ba-3e00-11e5-a0d2-18037327aaeb")
    end

    it "topology contains the expected structure when vm is off" do
      # vm and host test cross provider correlation to infra provider
      vm_rhev.update_attributes(:raw_power_state => "down")
      container_topology_service.stub(:retrieve_providers).and_return([ems_kube])

      container_group = ContainerGroup.create(:ext_management_system => ems_kube, :container_node => container_node,
                                              :name => "myPod", :ems_ref => "96c35ccd-3e00-11e5-a0d2-18037327aaeb",
                                              :phase => "Running", :container_definitions => [container_def])
      container_service = ContainerService.create(:ext_management_system => ems_kube, :container_groups => [container_group],
                                                  :ems_ref => "95e49048-3e00-11e5-a0d2-18037327aaeb",
                                                  :name => "service1")

      topology = container_topology_service.build_topology
      topology[:items].size.should eql 6
      topology[:relations].size.should eql 5

      topology[:items].key? "905c90ba-3e00-11e5-a0d2-18037327aaeb"

      topology[:items]["905c90ba-3e00-11e5-a0d2-18037327aaeb"].should eql(:id => "905c90ba-3e00-11e5-a0d2-18037327aaeb",
                                                                          :name => "127.0.0.1",
                                                                          :status => "Ready", :kind => "Node", :miq_id => container_node.id)
      topology[:items]["95e49048-3e00-11e5-a0d2-18037327aaeb"].should eql(:id => "95e49048-3e00-11e5-a0d2-18037327aaeb",
                                                                          :name => "service1",
                                                                          :status => "Unknown", :kind => "Service", :miq_id => container_service.id)
      topology[:items]["96c35ccd-3e00-11e5-a0d2-18037327aaeb"].should eql(:id => "96c35ccd-3e00-11e5-a0d2-18037327aaeb",
                                                                          :name => "myPod",
                                                                          :status => "Running", :kind => "Pod", :miq_id => container_group.id)
      topology[:items]["3572afee-3a41-11e5-a79a-001a4a231290_ruby-helloworld-database_openshift\n/mysql-55-centos7:latest"].should eql(:id => "3572afee-3a41-11e5-a79a-001a4a231290_ruby-helloworld-database_openshift\n/mysql-55-centos7:latest", :name => "ruby-example", :status => "Running", :kind => "Container",  :miq_id => container.id)

      topology[:items]["558d9a08-7b13-11e5-8546-129aa6621998"].should eql(:id => "558d9a08-7b13-11e5-8546-129aa6621998",
                                                                          :name => "vm1", :status => "Off",
                                                                          :kind => "VM", :miq_id => vm_rhev.id,
                                                                          :provider => "ems_rhev")

      topology[:relations].should include(:source => "95e49048-3e00-11e5-a0d2-18037327aaeb",
                                          :target => "96c35ccd-3e00-11e5-a0d2-18037327aaeb")
      topology[:relations].should include(:source => "905c90ba-3e00-11e5-a0d2-18037327aaeb",
                                          :target => "558d9a08-7b13-11e5-8546-129aa6621998")
    end
  end
end
