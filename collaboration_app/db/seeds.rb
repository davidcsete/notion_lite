# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating seed data..."

# Create test users
users = [
  {
    name: "Alice Johnson",
    email: "alice@example.com",
    password: "password123",
    avatar_url: "https://ui-avatars.com/api/?name=Alice+Johnson&background=0D8ABC&color=fff"
  },
  {
    name: "Bob Smith",
    email: "bob@example.com", 
    password: "password123",
    avatar_url: "https://ui-avatars.com/api/?name=Bob+Smith&background=DC2626&color=fff"
  },
  {
    name: "Carol Davis",
    email: "carol@example.com",
    password: "password123", 
    avatar_url: "https://ui-avatars.com/api/?name=Carol+Davis&background=059669&color=fff"
  },
  {
    name: "David Wilson",
    email: "david@example.com",
    password: "password123",
    avatar_url: "https://ui-avatars.com/api/?name=David+Wilson&background=7C3AED&color=fff"
  }
]

created_users = users.map do |user_attrs|
  User.find_or_create_by!(email: user_attrs[:email]) do |user|
    user.name = user_attrs[:name]
    user.password = user_attrs[:password]
    user.avatar_url = user_attrs[:avatar_url]
  end
end

alice, bob, carol, david = created_users

puts "Created #{created_users.length} users"

# Create sample notes
notes_data = [
  {
    title: "Project Planning Meeting Notes",
    content: {
      "type" => "doc",
      "content" => [
        {
          "type" => "heading",
          "attrs" => { "level" => 1 },
          "content" => [{ "type" => "text", "text" => "Project Planning Meeting" }]
        },
        {
          "type" => "paragraph",
          "content" => [
            { "type" => "text", "text" => "Date: " },
            { "type" => "text", "text" => "January 15, 2024", "marks" => [{ "type" => "bold" }] }
          ]
        },
        {
          "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "Attendees: Alice, Bob, Carol" }]
        },
        {
          "type" => "heading",
          "attrs" => { "level" => 2 },
          "content" => [{ "type" => "text", "text" => "Agenda Items" }]
        },
        {
          "type" => "bulletList",
          "content" => [
            {
              "type" => "listItem",
              "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Review project timeline" }] }]
            },
            {
              "type" => "listItem", 
              "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Assign team responsibilities" }] }]
            },
            {
              "type" => "listItem",
              "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Discuss technical requirements" }] }]
            }
          ]
        }
      ]
    },
    owner: alice
  },
  {
    title: "API Documentation Draft",
    content: {
      "type" => "doc",
      "content" => [
        {
          "type" => "heading",
          "attrs" => { "level" => 1 },
          "content" => [{ "type" => "text", "text" => "API Documentation" }]
        },
        {
          "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "This document outlines the REST API endpoints for our collaboration application." }]
        },
        {
          "type" => "heading",
          "attrs" => { "level" => 2 },
          "content" => [{ "type" => "text", "text" => "Authentication" }]
        },
        {
          "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "All API requests require authentication via session cookies." }]
        }
      ]
    },
    owner: bob
  },
  {
    title: "Team Brainstorming Session",
    content: {
      "type" => "doc",
      "content" => [
        {
          "type" => "heading",
          "attrs" => { "level" => 1 },
          "content" => [{ "type" => "text", "text" => "Brainstorming: New Features" }]
        },
        {
          "type" => "paragraph",
          "content" => [{ "type" => "text", "text" => "Ideas for improving user experience:" }]
        },
        {
          "type" => "bulletList",
          "content" => [
            {
              "type" => "listItem",
              "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Dark mode support" }] }]
            },
            {
              "type" => "listItem",
              "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Mobile app version" }] }]
            },
            {
              "type" => "listItem",
              "content" => [{ "type" => "paragraph", "content" => [{ "type" => "text", "text" => "Integration with external tools" }] }]
            }
          ]
        }
      ]
    },
    owner: carol
  }
]

created_notes = notes_data.map do |note_attrs|
  Note.find_or_create_by!(title: note_attrs[:title], owner: note_attrs[:owner]) do |note|
    note.content = note_attrs[:content]
    note.document_state = { "version" => 0, "operations" => [] }
  end
end

puts "Created #{created_notes.length} notes"

# Create collaborations
collaborations_data = [
  # Alice's note - add Bob as editor, Carol as viewer
  { note: created_notes[0], user: bob, role: :editor },
  { note: created_notes[0], user: carol, role: :viewer },
  
  # Bob's note - add Alice as editor, David as viewer  
  { note: created_notes[1], user: alice, role: :editor },
  { note: created_notes[1], user: david, role: :viewer },
  
  # Carol's note - add Alice and Bob as editors
  { note: created_notes[2], user: alice, role: :editor },
  { note: created_notes[2], user: bob, role: :editor }
]

created_collaborations = collaborations_data.map do |collab_attrs|
  Collaboration.find_or_create_by!(
    note: collab_attrs[:note],
    user: collab_attrs[:user]
  ) do |collaboration|
    collaboration.role = collab_attrs[:role]
  end
end

puts "Created #{created_collaborations.length} collaborations"

# Create some sample operations for testing operational transformation
sample_operations = [
  {
    note: created_notes[0],
    user: bob,
    operation_type: :op_insert,
    position: 100,
    content: 'Additional notes from Bob: ',
    timestamp: 1.hour.ago
  },
  {
    note: created_notes[0], 
    user: carol,
    operation_type: :op_insert,
    position: 150,
    content: 'Carol suggests we also consider budget constraints.',
    timestamp: 30.minutes.ago
  },
  {
    note: created_notes[1],
    user: alice,
    operation_type: :op_insert, 
    position: 200,
    content: "\n\n## Error Handling\n\nAll endpoints return appropriate HTTP status codes.",
    timestamp: 45.minutes.ago
  }
]

created_operations = sample_operations.map do |op_attrs|
  Operation.create!(op_attrs.merge(applied: true))
end

puts "Created #{created_operations.length} sample operations"

puts "Seed data creation completed!"
puts ""
puts "Test users created:"
users.each do |user|
  puts "  - #{user[:name]} (#{user[:email]}) - password: #{user[:password]}"
end
puts ""
puts "You can now test the application with these users and their collaborative notes."
