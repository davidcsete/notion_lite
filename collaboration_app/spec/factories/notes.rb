FactoryBot.define do
  factory :note do
    sequence(:title) { |n| "Note #{n}" }
    content { { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Sample note content" }] }] } }
    document_state { { "version" => 0, "operations" => [] } }
    association :owner, factory: :user
  end
end
