FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    avatar_url { |user| "https://ui-avatars.com/api/?name=#{user.name.gsub(' ', '+')}&background=0D8ABC&color=fff" }
  end
end
