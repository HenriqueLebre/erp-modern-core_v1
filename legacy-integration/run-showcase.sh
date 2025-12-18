#!/bin/bash

# 🚀 Legacy Integration Showcase Runner
# 
# This script runs the complete demonstration of XHarbour → .NET 8 integration
# Perfect for portfolio presentations and technical interviews

set -e  # Exit on any error

echo "🚀 ERP Modernization Showcase"
echo "============================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if API is running
check_api() {
    print_step "Checking if Auth API is running..."
    
    if curl -s http://localhost:5281/health > /dev/null 2>&1; then
        print_success "Auth API is running and healthy!"
        return 0
    else
        print_warning "Auth API is not running on localhost:5281"
        echo ""
        echo "Please start the API first:"
        echo "  cd src/Modules/Auth/Auth.API"
        echo "  dotnet run"
        echo ""
        echo "Then run this showcase again."
        return 1
    fi
}

# Check Python availability
check_python() {
    print_step "Checking Python availability..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
        print_success "Python 3 found: $(python3 --version)"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
        print_success "Python found: $(python --version)"
    else
        print_error "Python not found. Please install Python 3.7+ to run the demo."
        return 1
    fi
}

# Install required packages
install_requirements() {
    print_step "Installing required Python packages..."
    
    $PYTHON_CMD -c "import requests" 2>/dev/null || {
        print_warning "Installing requests package..."
        pip install requests || pip3 install requests || {
            print_error "Failed to install requests package"
            echo "Please install manually: pip install requests"
            return 1
        }
    }
    
    print_success "Python dependencies ready"
}

# Run API tests
run_api_tests() {
    print_step "Running Auth API security tests..."
    echo ""
    
    cd demo
    $PYTHON_CMD quick_api_test.py
    cd ..
    
    echo ""
    print_success "API security tests completed!"
}

# Run legacy integration demo
run_integration_demo() {
    print_step "Running Legacy Integration Demo..."
    echo ""
    echo "This demonstrates how XHarbour legacy system integrates with modern Auth API..."
    echo ""
    
    cd demo
    $PYTHON_CMD legacy_integration_demo.py
    cd ..
    
    echo ""
    print_success "Legacy integration demo completed!"
}

# Show summary
show_summary() {
    echo ""
    echo "🎯 SHOWCASE SUMMARY"
    echo "=================="
    echo ""
    echo "✅ Modern .NET 8 Auth API with security features:"
    echo "   • JWT authentication with PBKDF2 password hashing"
    echo "   • Rate limiting (5 login attempts/min per IP)"
    echo "   • Health checks for monitoring (/health, /health/ready, /health/live)"
    echo "   • Token validation endpoint (/auth/validate)"
    echo "   • User info endpoint (/auth/me)"
    echo ""
    echo "✅ Legacy XHarbour Integration:"
    echo "   • HTTP wrapper for seamless API integration"
    echo "   • Strangler Fig migration pattern"
    echo "   • Business continuity during modernization"
    echo "   • Role-based access control"
    echo ""
    echo "✅ Perfect for Portfolio:"
    echo "   • Real-world legacy modernization challenge"
    echo "   • Multiple technology stacks (XHarbour + .NET 8)"
    echo "   • Enterprise security requirements"
    echo "   • AWS Free Tier ready architecture"
    echo ""
    echo "📁 Files demonstrated:"
    echo "   • xharbour-wrapper/AuthAPI.prg - Production XHarbour wrapper"
    echo "   • demo/legacy_integration_demo.py - Interactive showcase"
    echo "   • demo/quick_api_test.py - API validation tests"
    echo ""
    echo "🚀 Next steps for full showcase:"
    echo "   1. Deploy to AWS Free Tier (RDS + Fargate)"
    echo "   2. Set up CI/CD with GitHub Actions"
    echo "   3. Add basic monitoring/logging"
    echo ""
    echo "Perfect for technical interviews and portfolio presentations!"
}

# Main execution
main() {
    # Pre-flight checks
    if ! check_api; then
        exit 1
    fi
    
    if ! check_python; then
        exit 1
    fi
    
    if ! install_requirements; then
        exit 1
    fi
    
    echo ""
    
    # Run demonstrations
    run_api_tests
    
    echo ""
    echo "Press Enter to continue with Legacy Integration Demo..."
    read -r
    
    run_integration_demo
    
    # Show final summary
    show_summary
}

# Check if we're in the right directory
if [ ! -f "demo/legacy_integration_demo.py" ]; then
    print_error "Please run this script from the legacy-integration directory:"
    echo "  cd erp-modern-core/legacy-integration"
    echo "  ./run-showcase.sh"
    exit 1
fi

# Run main function
main