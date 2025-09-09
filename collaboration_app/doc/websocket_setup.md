# WebSocket Infrastructure Setup

## Overview

This document describes the Action Cable WebSocket infrastructure implemented for real-time collaboration features.

## Components

### 1. Action Cable Connection (`app/channels/application_cable/connection.rb`)

Handles WebSocket connection authentication using session-based authentication:

- Identifies users by `current_user` from session
- Rejects unauthorized connections
- Integrates with existing Rails authentication system

### 2. NoteChannel (`app/channels/note_channel.rb`)

Main channel for real-time note collaboration:

**Features:**
- User presence tracking with Redis
- Real-time operation broadcasting (insert, delete, retain)
- Cursor position sharing
- Typing indicators
- Role-based access control (owner, editor, viewer)
- Automatic conflict resolution preparation

**Message Types:**
- `operation`: Document edit operations
- `cursor`: Cursor position updates  
- `typing`: Typing status indicators
- `user_joined`: User presence notifications
- `user_left`: User departure notifications

### 3. Configuration

**Cable Configuration (`config/cable.yml`):**
- Development: Redis adapter on `redis://localhost:6379/1`
- Test: Test adapter for isolated testing
- Production: Solid Cable for deployment

**CORS Configuration:**
- Allows WebSocket connections from frontend (`localhost:5173`)
- Credentials enabled for session authentication

**Routes:**
- WebSocket endpoint mounted at `/cable`

## Usage

### Frontend Connection

```javascript
// Connect to WebSocket
const cable = ActionCable.createConsumer('ws://localhost:3000/cable');

// Subscribe to note channel
const subscription = cable.subscriptions.create(
  { channel: 'NoteChannel', note_id: noteId },
  {
    received(data) {
      // Handle incoming messages
      switch(data.type) {
        case 'operation':
          // Apply document operation
          break;
        case 'cursor':
          // Update cursor position
          break;
        case 'user_joined':
          // Show user joined
          break;
      }
    }
  }
);

// Send operation
subscription.send({
  type: 'operation',
  operation: {
    type: 'insert',
    position: 10,
    content: 'Hello World'
  }
});
```

### Backend Broadcasting

```ruby
# Broadcast to all note subscribers
NoteChannel.broadcast_to(note, {
  type: 'operation',
  operation: operation_data
});
```

## Security

- Session-based authentication for WebSocket connections
- Role-based authorization for note access
- Edit permissions enforced for operations
- Presence data isolated per note

## Testing

Comprehensive test suite covers:
- Connection authentication
- Channel subscription/unsubscription
- Message handling and broadcasting
- Authorization and permissions
- Presence tracking
- Redis integration (mocked)

Run tests:
```bash
bundle exec rspec spec/channels/
```

## Redis Integration

- User presence stored in Redis with TTL
- Automatic cleanup on disconnect
- Scalable across multiple server instances
- Fallback graceful degradation

## Performance Considerations

- Operations stored in database for conflict resolution
- Redis used for ephemeral presence data
- Efficient broadcasting to connected clients only
- Automatic connection cleanup

## Deployment Notes

- Ensure Redis is available and configured
- Set appropriate CORS origins for production
- Configure Action Cable allowed request origins
- Monitor WebSocket connection limits
- Set up Redis persistence if needed