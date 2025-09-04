#!/bin/bash

echo "Starting development environment..."

# Start Docker services
echo "Starting PostgreSQL and Redis..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# Setup Rails database
echo "Setting up Rails database..."
cd collaboration_app
bundle exec rails db:create
bundle exec rails db:migrate
cd ..

echo "Development environment is ready!"
echo ""
echo "To start the Rails server: cd collaboration_app && rails server"
echo "To start the Vue frontend: cd frontend && npm run dev"
echo "To stop services: docker-compose down"