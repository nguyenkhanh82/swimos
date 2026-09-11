#!/bin/bash
# Setup script for SwimScraper with database support

echo "SwimScraper Database Setup"
echo "=========================="
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo "Virtual environment created!"
else
    echo "Virtual environment already exists."
fi

# Activate virtual environment
echo ""
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo ""
echo "Installing dependencies..."
pip install -e .

# Check PostgreSQL
echo ""
echo "Checking PostgreSQL..."
if command -v psql &> /dev/null; then
    echo "PostgreSQL is installed."
    if pg_ctl -D /opt/homebrew/var/postgresql@14 status &> /dev/null; then
        echo "PostgreSQL is running."
    else
        echo "PostgreSQL is not running. Starting it..."
        brew services start postgresql@14 || pg_ctl -D /opt/homebrew/var/postgresql@14 start
        sleep 2
    fi
else
    echo "PostgreSQL not found. Please install it first:"
    echo "  brew install postgresql@14"
    exit 1
fi

# Initialize database
echo ""
echo "Initializing database..."
python3 src/SwimScraper/init_db.py

echo ""
echo "=========================="
echo "Setup complete!"
echo ""
echo "To use SwimScraper, activate the virtual environment:"
echo "  source venv/bin/activate"
echo ""
echo "Then run the scraper:"
echo "  python run_scraper.py"
