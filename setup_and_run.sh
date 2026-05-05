#!/bin/bash
# ─────────────────────────────────────────────────────────
# Global Universities Explorer — Setup & Run Script
# ─────────────────────────────────────────────────────────

set -e

echo "🎓 Global Universities Explorer — Setup"
echo "========================================"

# 1. Install Python dependencies
echo ""
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt --quiet

# 2. PostgreSQL setup
echo ""
echo "🗄️  Setting up PostgreSQL database..."
echo "   Make sure PostgreSQL is running and update DB credentials in .env if needed."

# Create .env if it doesn't exist
if [ ! -f .env ]; then
cat > .env << 'EOF'
DB_NAME=universities_db
DB_USER=postgres_ict_project
DB_PASSWORD=postgres
DB_HOST=localhost
DB_PORT=5432
FLASK_ENV=development
FLASK_DEBUG=1
EOF
echo "   ✅ Created .env file. Edit DB credentials if needed."
fi

# Create database and load schema
echo ""
echo "   Creating database 'universities_db'..."
psql -U postgres -c "CREATE DATABASE universities_db;" 2>/dev/null || echo "   (Database may already exist, continuing...)"

echo "   Loading schema and seed data..."
psql -U postgres -d universities_db -f schema.sql
echo "   ✅ Database populated successfully!"

# 3. Run the app
echo ""
echo "🚀 Starting Flask application..."
echo "   Open: http://localhost:5000"
echo ""
export FLASK_APP=app.py
export FLASK_DEBUG=1
python app.py
