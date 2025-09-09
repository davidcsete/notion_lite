class NoteChannel < ApplicationCable::Channel
  def subscribed
    note = Note.find(params[:note_id])
    
    # Check if user has access to this note
    unless can_access_note?(note)
      reject
      return
    end

    @note = note
    stream_for note
    
    # Track user presence
    add_user_presence
    broadcast_user_joined
  end

  def unsubscribed
    remove_user_presence if @note
    broadcast_user_left if @note
  end

  def receive(data)
    return unless @note && can_access_note?(@note)

    case data['type']
    when 'operation'
      handle_operation(data)
    when 'cursor'
      handle_cursor_update(data)
    when 'typing'
      handle_typing_indicator(data)
    end
  end

  private

  def can_access_note?(note)
    # Check if user is owner or has collaboration access
    return true if note.owner == current_user
    
    collaboration = note.collaborations.find_by(user: current_user)
    collaboration.present?
  end

  def can_edit_note?(note)
    # Check if user has edit permissions
    return true if note.owner == current_user
    
    collaboration = note.collaborations.find_by(user: current_user)
    collaboration&.role&.in?(['editor'])
  end

  def handle_operation(data)
    return unless can_edit_note?(@note)

    # Map operation types to enum values
    type_mapping = { 'insert' => 'op_insert', 'delete' => 'op_delete', 'retain' => 'op_retain' }
    operation_type = type_mapping[data['operation']['type']] || data['operation']['type']

    # Create operation record for conflict resolution
    operation = @note.operations.create!(
      user: current_user,
      operation_type: operation_type,
      position: data['operation']['position'],
      content: data['operation']['content'],
      timestamp: Time.current
    )

    # Broadcast operation to all other users
    # Map back to client-friendly operation types
    client_type_mapping = { 'op_insert' => 'insert', 'op_delete' => 'delete', 'op_retain' => 'retain' }
    client_type = client_type_mapping[operation.operation_type] || operation.operation_type
    
    NoteChannel.broadcast_to(@note, {
      type: 'operation',
      operation: {
        id: operation.id,
        type: client_type,
        position: operation.position,
        content: operation.content,
        user_id: current_user.id,
        user_name: current_user.name,
        timestamp: operation.timestamp.iso8601(3)
      }
    })

    # Update note content (simplified - in production would use operational transformation)
    update_note_content(data['operation'])
  end

  def handle_cursor_update(data)
    # Broadcast cursor position to other users
    NoteChannel.broadcast_to(@note, {
      type: 'cursor',
      user_id: current_user.id,
      user_name: current_user.name,
      position: data['position'],
      selection: data['selection']
    })
  end

  def handle_typing_indicator(data)
    # Broadcast typing status to other users
    NoteChannel.broadcast_to(@note, {
      type: 'typing',
      user_id: current_user.id,
      user_name: current_user.name,
      is_typing: data['is_typing']
    })
  end

  def add_user_presence
    # Add user to Redis set for presence tracking
    redis_key = "note:#{@note.id}:users"
    user_data = {
      id: current_user.id,
      name: current_user.name,
      email: current_user.email,
      joined_at: Time.current.iso8601
    }
    
    redis.hset(redis_key, current_user.id, user_data.to_json)
    redis.expire(redis_key, 1.hour)
  end

  def remove_user_presence
    redis_key = "note:#{@note.id}:users"
    redis.hdel(redis_key, current_user.id)
  end

  def broadcast_user_joined
    # Get current users for this note
    active_users = get_active_users
    
    NoteChannel.broadcast_to(@note, {
      type: 'user_joined',
      user: {
        id: current_user.id,
        name: current_user.name,
        email: current_user.email
      },
      active_users: active_users
    })
  end

  def broadcast_user_left
    # Get remaining users for this note
    active_users = get_active_users
    
    NoteChannel.broadcast_to(@note, {
      type: 'user_left',
      user_id: current_user.id,
      active_users: active_users
    })
  end

  def get_active_users
    redis_key = "note:#{@note.id}:users"
    user_data = redis.hgetall(redis_key)
    
    user_data.map do |user_id, data|
      JSON.parse(data)
    end
  end

  def redis
    @redis ||= Redis.new(url: Rails.application.config.action_cable.adapter['url'] || 'redis://localhost:6379/1')
  end

  def update_note_content(operation)
    # Simplified content update - in production would use operational transformation
    # For now, we'll just update the document state version to indicate changes
    current_state = @note.document_state || { "version" => 0, "operations" => [] }
    current_state["version"] = (current_state["version"] || 0) + 1
    current_state["operations"] ||= []
    current_state["operations"] << {
      "type" => operation['type'],
      "position" => operation['position'],
      "content" => operation['content'],
      "timestamp" => Time.current.iso8601(3)
    }
    
    @note.update!(document_state: current_state)
  end
end