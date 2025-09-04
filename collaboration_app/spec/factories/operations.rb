FactoryBot.define do
  factory :operation do
    association :note
    association :user
    operation_type { :op_insert }
    position { 0 }
    content { "Sample text" }
    timestamp { Time.current }
    applied { false }

    trait :insert do
      operation_type { :op_insert }
      content { "Inserted text" }
    end

    trait :delete do
      operation_type { :op_delete }
      content { nil }
    end

    trait :retain do
      operation_type { :op_retain }
      content { nil }
    end

    trait :applied do
      applied { true }
    end
  end
end
