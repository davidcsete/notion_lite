# Real-Time Collaboration App

A Notion-lite application that enables users to create and collaboratively edit shared notes in real-time.

## Tech Stack

- **Backend**: Ruby on Rails 7 with Action Cable for WebSockets
- **Frontend**: Vue.js 3 with Composition API, TailwindCSS, DaisyUI
- **Database**: PostgreSQL for persistent data, Redis for real-time data
- **Real-time**: Action Cable with Redis adapter for WebSocket scaling

## Development Setup

### Prerequisites

- Ruby 3.x
- Node.js 18+
- Docker and Docker Compose

### Quick Start

1. **Start the development environment:**
   ```bash
   ./start-dev.sh
   ```

2. **Start the Rails server:**
   ```bash
   cd collaboration_app
   rails server
   ```

3. **Start the Vue frontend (in another terminal):**
   ```bash
   cd frontend
   npm run dev
   ```

### Manual Setup

1. **Start Docker services:**
   ```bash
   docker-compose up -d
   ```

2. **Setup Rails:**
   ```bash
   cd collaboration_app
   bundle install
   rails db:create
   rails db:migrate
   ```

3. **Setup Frontend:**
   ```bash
   cd frontend
   npm install
   ```

## Services

- **Rails API**: http://localhost:3000
- **Vue Frontend**: http://localhost:5173
- **PostgreSQL**: localhost:5433
- **Redis**: localhost:6379

## Project Structure

```
├── collaboration_app/     # Rails API backend
├── frontend/             # Vue.js frontend
├── docker-compose.yml    # Database services
└── start-dev.sh         # Development setup script
```

## Next Steps

Follow the implementation tasks in `.kiro/specs/real-time-collaboration-app/tasks.md` to build the application features.