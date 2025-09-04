FactoryBot.define do
  factory :collaboration do
    association :user
    association :note
    role { :editor }

    trait :editor do
      role { :editor }
    end

    trait :viewer do
      role { :viewer }
    end
  end
end
