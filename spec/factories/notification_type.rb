FactoryGirl.define do
  factory :notification_type do
    sequence(:name) { |n| "notification_type_#{seq_padded_for_sorting(n)}" }
    sequence(:message) { |n| "message_#{seq_padded_for_sorting(n)}" }
    level "info"
  end
end
