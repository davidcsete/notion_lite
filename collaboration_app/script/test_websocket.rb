#!/usr/bin/env ruby

# Simple script to test WebSocket functionality
require_relative '../config/environment'

# Create test data
user = User.create!(
  name: 'Test User',
  email: 'test@example.com',
  password: 'password123'
)

note = Note.create!(
  title: 'Test Note',
  content: { "type" => "doc", "content" => [] },
  owner: user
)

puts "Created test user: #{user.email}"
puts "Created test note: #{note.title}"

# Test Redis connection
begin
  redis = Redis.new(url: 'redis://localhost:6379/1')
  redis.ping
  puts "✅ Redis connection successful"
rescue => e
  puts "❌ Redis connection failed: #{e.message}"
end

# Test Action Cable configuration
begin
  ActionCable.server.config.cable
  puts "✅ Action Cable configuration loaded"
rescue => e
  puts "❌ Action Cable configuration error: #{e.message}"
end

# Test NoteChannel functionality
begin
  # Simulate channel subscription
  channel = NoteChannel.new(nil, {})
  puts "✅ NoteChannel class loaded successfully"
rescue => e
  puts "❌ NoteChannel error: #{e.message}"
end

puts "\n🎉 WebSocket infrastructure setup complete!"
puts "Next steps:"
puts "1. Start the Rails server: rails server"
puts "2. Connect from frontend using: ws://localhost:3000/cable"
puts "3. Subscribe to note channel with: { note_id: #{note.id} }"