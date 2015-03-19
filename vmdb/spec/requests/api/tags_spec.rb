#
# REST API Request Tests - /api/tags
#
require 'spec_helper'

describe ApiController do

  include Rack::Test::Methods

  let(:zone)         { FactoryGirl.create(:zone, :name => "api_zone") }
  let(:miq_server)   { FactoryGirl.create(:miq_server, :guid => miq_server_guid, :zone => zone) }
  let(:ems)          { FactoryGirl.create(:ems_vmware, :zone => zone) }
  let(:host)         { FactoryGirl.create(:host) }

  let(:tag1)         { {:category => "department", :name => "finance", :path => "/managed/department/finance"} }
  let(:tag2)         { {:category => "cc",         :name => "001",     :path => "/managed/cc/001"} }

  let(:vm1) { FactoryGirl.create(:vm_vmware, :host => host, :ems_id => ems.id, :raw_power_state => "poweredOn") }
  let(:vm1_url)      { vms_url(vm1.id) }
  let(:vm1_tags_url) { "#{vm1_url}/tags" }

  let(:vm2) { FactoryGirl.create(:vm_vmware, :host => host, :ems_id => ems.id, :raw_power_state => "poweredOn") }
  let(:vm2_url)      { vms_url(vm2.id) }
  let(:vm2_tags_url) { "#{vm2_url}/tags" }

  let(:invalid_tag_url) { tags_url(999_999) }

  let(:tag_count)    { Tag.count }

  before(:each) do
    init_api_spec_env

    FactoryGirl.create(:classification_department_with_tags)
    FactoryGirl.create(:classification_cost_center_with_tags)

    Classification.classify(vm2, tag1[:category], tag1[:name])
    Classification.classify(vm2, tag2[:category], tag2[:name])
  end

  def app
    Vmdb::Application
  end

  context "Tag collection" do
    context "query all tags" do
      before do
        api_basic_authorize

        run_get tags_url
      end

      it "query_result" do
        expect_query_result(:tags, :tag_count)
      end
    end

    context "query a tag with an invalid Id" do
      before do
        api_basic_authorize

        run_get invalid_tag_url
      end

      it "resource_not_found" do
        expect_resource_not_found
      end
    end

    context "query tags with expanded resources" do
      before do
        api_basic_authorize

        run_get "#{tags_url}?expand=resources"
      end

      it "query_result" do
        expect_query_result(:tags, :tag_count, :tag_count)
        expect_result_resources_to_include_keys("resources", %w(id name))
      end
    end

    context "query tag details with multiple virtual attributes" do
      before do
        api_basic_authorize

        attr_list = "category.name,category.description,classification.name,classification.description"
        run_get "#{tags_url(Tag.last.id)}?attributes=#{attr_list}"
      end

      it "single_resource_query" do
        tag = Tag.last
        expect_single_resource_query(
          "href"           => tags_url(tag.id),
          "id"             => tag.id,
          "name"           => tag.name,
          "category"       => {"name" => tag.category.name,       "description" => tag.category.description},
          "classification" => {"name" => tag.classification.name, "description" => tag.classification.description}
        )
      end
    end

    context "query tag details with categorization" do
      before do
        api_basic_authorize

        run_get "#{tags_url(Tag.last.id)}?attributes=categorization"
      end

      it "single_resource_query" do
        tag = Tag.last
        expect_single_resource_query(
         "href"           => tags_url(tag.id),
         "id"             => tag.id,
         "name"           => tag.name,
         "categorization" => {
           "name"         => tag.classification.name,
           "description"  => tag.classification.description,
           "display_name" => "#{tag.category.description}: #{tag.classification.description}",
           "category"     => {"name" => tag.category.name, "description" => tag.category.description}
         }
       )
      end
    end

    context "query all tags with categorization" do
      before do
        api_basic_authorize

        run_get "#{tags_url}?expand=resources&attributes=categorization"
      end

      it "query_result" do
        expect_query_result(:tags, :tag_count, :tag_count)
        expect_result_resources_to_include_keys("resources", %w(id name categorization))
      end
    end
  end

  context "Vm Tag subcollection" do
    context "query all tags of a Vm with no tags" do
      before do
        api_basic_authorize

        run_get vm1_tags_url
      end

      it "empty_query_result" do
        expect_empty_query_result(:tags)
      end
    end

    context "query all tags of a Vm" do
      before do
        api_basic_authorize

        run_get vm2_tags_url
      end

      it "query_result" do
        expect_query_result(:tags, 2, :tag_count)
      end
    end

    context "query all tags of a Vm and verify tag category and names" do
      def tag_paths
        [tag1[:path], tag2[:path]]
      end

      before do
        api_basic_authorize

        run_get "#{vm2_tags_url}?expand=resources"
      end

      it "query_result" do
        expect_query_result(:tags, 2, :tag_count)
        expect_result_resources_to_include_data("resources", "name" => :tag_paths)
      end
    end

    context "assigns a tag to a Vm without appropriate role" do
      before do
        api_basic_authorize

        run_post(vm1_tags_url, gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))
      end

      it "request_forbidden" do
        expect_request_forbidden
      end
    end

    context "assigns a tag to a Vm" do
      let(:tag_results) do
        [{:success => true, :href => vm1_url, :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      end

      before do
        api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

        run_post(vm1_tags_url, gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))
      end

      it "tagging_result" do
        expect_tagging_result(:tag_results)
      end
    end

    context "assigns a tag to a Vm by name path" do
      let(:tag_results) do
        [{:success => true, :href => vm1_url, :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      end

      before do
        api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

        run_post(vm1_tags_url, gen_request(:assign, :name => tag1[:path]))
      end

      it "tagging_result" do
        expect_tagging_result(:tag_results)
      end
    end

    context "assigns a tag to a Vm by href" do
      let(:tag_results) do
        [{:success => true, :href => vm1_url, :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      end

      before do
        api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

        tag = Tag.find_by_name(tag1[:path])
        run_post(vm1_tags_url, gen_request(:assign, :href => tags_url(tag.id)))
      end

      it "tagging_result" do
        expect_tagging_result(:tag_results)
      end
    end

    context "assigns an invalid tag by href to a Vm" do
      before do
        api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

        run_post(vm1_tags_url, gen_request(:assign, :href => invalid_tag_url))
      end

      it "resource_not_found" do
        expect_resource_not_found
      end
    end

    context "assigns an invalid tag to a Vm" do
      let(:tag_results) do
        [{:success => false, :href => vm1_url, :tag_category => "bad_category", :tag_name => "bad_name"}]
      end

      before do
        api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

        run_post(vm1_tags_url, gen_request(:assign, :name => "/managed/bad_category/bad_name"))
      end

      it "tagging_result" do
        expect_tagging_result(:tag_results)
      end
    end

    context "assigns multiple tags to a Vm" do
      let(:tag_results) do
        [{:success => true, :href => vm1_url, :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => vm1_url, :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      end

      before do
        api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

        run_post(vm1_tags_url, gen_request(:assign, [{:name => tag1[:path]}, {:name => tag2[:path]}]))
      end

      it "tagging_result" do
        expect_tagging_result(:tag_results)
      end
    end

    context "assigns tags by mixed specification to a Vm" do
      let(:tag_results) do
        [{:success => true, :href => vm1_url, :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => vm1_url, :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      end

      before do
        api_basic_authorize subcollection_action_identifier(:vms, :tags, :assign)

        tag = Tag.find_by_name(tag2[:path])
        run_post(vm1_tags_url, gen_request(:assign, [{:name => tag1[:path]}, {:href => tags_url(tag.id)}]))
      end

      it "tagging_result" do
        expect_tagging_result(:tag_results)
      end
    end

    context "unassigns a tag from a Vm without appropriate role" do
      before do
        api_basic_authorize

        run_post(vm1_tags_url, gen_request(:assign, :category => tag1[:category], :name => tag1[:name]))
      end

      it "request_forbidden" do
        expect_request_forbidden
      end
    end

    context "unassigns a tag from a Vm" do
      let(:tag_results) do
        [{:success => true, :href => vm2_url, :tag_category => tag1[:category], :tag_name => tag1[:name]}]
      end

      before do
        api_basic_authorize subcollection_action_identifier(:vms, :tags, :unassign)

        run_post(vm2_tags_url, gen_request(:unassign, :category => tag1[:category], :name => tag1[:name]))
      end

      it "tagging_result" do
        expect_tagging_result(:tag_results)
        expect(vm2.tags.count).to eq(1)
        expect(vm2.tags.first.name).to eq(tag2[:path])
      end
    end

    context "unassigns multiple tags from a Vm" do
      let(:tag_results) do
        [{:success => true, :href => vm2_url, :tag_category => tag1[:category], :tag_name => tag1[:name]},
         {:success => true, :href => vm2_url, :tag_category => tag2[:category], :tag_name => tag2[:name]}]
      end

      before do
        api_basic_authorize subcollection_action_identifier(:vms, :tags, :unassign)

        tag = Tag.find_by_name(tag2[:path])
        run_post(vm2_tags_url, gen_request(:unassign, [{:name => tag1[:path]}, {:href => tags_url(tag.id)}]))
      end

      it "tagging_result" do
        expect_tagging_result(:tag_results)
        expect(vm2.tags.count).to eq(0)
      end
    end
  end
end
