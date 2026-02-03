#!/bin/bash

################################################################################
# PROPHETIA Deployment Script
# "Divine the Future. Reveal Nothing."
#
# This script automates the deployment of PROPHETIA contracts to Aleo testnet
#
# Usage:
#   ./scripts/deploy.sh [network]
#
# Arguments:
#   network - Optional: testnet3 (default) or mainnet
#
# Prerequisites:
#   1. Leo installed (leo --version)
#   2. Aleo account configured with private key
#   3. Testnet credits (from https://faucet.aleo.org/)
#
# Version: 0.1.0
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
NETWORK=${1:-testnet3}
CONTRACTS_DIR="contracts"
PROGRAM_NAME="prophetia.aleo"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                      PROPHETIA                            ║"
    echo "║           Divine the Future. Reveal Nothing.              ║"
    echo "║                                                           ║"
    echo "║           Zero-Knowledge ML Prediction Engine             ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}==>${NC} ${1}"
}

print_success() {
    echo -e "${GREEN}✓${NC} ${1}"
}

print_error() {
    echo -e "${RED}✗${NC} ${1}"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} ${1}"
}

################################################################################
# Pre-deployment Checks
################################################################################

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if Leo is installed
    if ! command -v leo &> /dev/null; then
        print_error "Leo is not installed. Please install it first:"
        echo "  curl -L https://raw.githubusercontent.com/AleoHQ/leo/testnet3/install.sh | sh"
        exit 1
    fi
    print_success "Leo is installed: $(leo --version)"
    
    # Check if in correct directory
    if [ ! -d "$CONTRACTS_DIR" ]; then
        print_error "Contracts directory not found. Are you in the project root?"
        exit 1
    fi
    print_success "Project structure validated"
    
    # Check if program.json exists
    if [ ! -f "$CONTRACTS_DIR/program.json" ]; then
        print_error "program.json not found in contracts directory"
        exit 1
    fi
    print_success "Program configuration found"
    
    # Check if source files exist
    if [ ! -f "$CONTRACTS_DIR/src/main.leo" ]; then
        print_error "main.leo not found"
        exit 1
    fi
    print_success "Source files validated"
}

################################################################################
# Build Process
################################################################################

build_contracts() {
    print_step "Building PROPHETIA contracts..."
    
    cd "$CONTRACTS_DIR"
    
    # Clean previous builds
    if [ -d "build" ]; then
        print_warning "Cleaning previous build artifacts..."
        rm -rf build
    fi
    
    # Build the project
    print_step "Compiling Leo contracts..."
    if leo build; then
        print_success "Contracts compiled successfully"
    else
        print_error "Build failed"
        cd ..
        exit 1
    fi
    
    cd ..
}

################################################################################
# Testing (Optional)
################################################################################

run_tests() {
    print_step "Running tests..."
    
    cd "$CONTRACTS_DIR"
    
    # Check if tests directory exists
    if [ -d "../tests" ] && [ "$(ls -A ../tests/*.leo 2>/dev/null)" ]; then
        print_step "Executing test suite..."
        if leo test; then
            print_success "All tests passed"
        else
            print_warning "Some tests failed. Continue anyway? (y/n)"
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                cd ..
                exit 1
            fi
        fi
    else
        print_warning "No tests found. Skipping test execution."
    fi
    
    cd ..
}

################################################################################
# Deployment
################################################################################

deploy_to_network() {
    print_step "Deploying to $NETWORK..."
    
    cd "$CONTRACTS_DIR"
    
    # Check for private key
    if [ -z "$PRIVATE_KEY" ]; then
        print_warning "PRIVATE_KEY environment variable not set"
        echo "Please enter your Aleo private key (or press Ctrl+C to cancel):"
        read -rs PRIVATE_KEY
    fi
    
    # Verify account has credits
    print_step "Verifying account balance..."
    # Note: Add actual balance check here when Leo CLI supports it
    print_warning "Please ensure your account has sufficient credits for deployment"
    echo "Continue with deployment? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        cd ..
        exit 0
    fi
    
    # Deploy the program
    print_step "Deploying $PROGRAM_NAME to $NETWORK..."
    print_warning "This may take several minutes..."
    
    # Actual deployment command (adjust based on Leo CLI version)
    # This is a placeholder - adjust based on actual Leo deployment commands
    if leo deploy --network "$NETWORK"; then
        print_success "Deployment successful!"
    else
        print_error "Deployment failed"
        cd ..
        exit 1
    fi
    
    cd ..
}

################################################################################
# Post-deployment
################################################################################

save_deployment_info() {
    print_step "Saving deployment information..."
    
    DEPLOY_DIR="deployments/$NETWORK"
    mkdir -p "$DEPLOY_DIR"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    DEPLOY_FILE="$DEPLOY_DIR/deployment_$TIMESTAMP.json"
    
    cat > "$DEPLOY_FILE" << EOF
{
  "program": "$PROGRAM_NAME",
  "network": "$NETWORK",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "version": "0.1.0",
  "status": "deployed",
  "contracts": {
    "main": "main.leo",
    "data_records": "data_records.leo",
    "models": "models.leo",
    "math_utils": "math_utils.leo"
  }
}
EOF
    
    print_success "Deployment info saved to $DEPLOY_FILE"
}

print_next_steps() {
    echo -e "\n${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                 Deployment Successful! 🎉                  ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${BLUE}Next Steps:${NC}"
    echo "1. Test your deployment with sample data:"
    echo "   leo run submit_data 1500000u64 1u8 850000u64"
    echo ""
    echo "2. Register a model:"
    echo "   leo run register_model '[500000u64, 300000u64, 150000u64, 50000u64]' 100000u64 1u8 750000u64 900000u64"
    echo ""
    echo "3. Make a prediction:"
    echo "   leo run make_prediction <model_record> '[1200000u64, 980000u64, 1050000u64, 1100000u64]'"
    echo ""
    echo "4. View on Aleo Explorer:"
    echo "   https://explorer.aleo.org/program/$PROGRAM_NAME"
    echo ""
    echo -e "${YELLOW}Documentation:${NC}"
    echo "  • README.md - Project overview"
    echo "  • docs/ARCHITECTURE.md - System architecture"
    echo ""
    echo -e "${PURPLE}Join the community:${NC}"
    echo "  • GitHub: https://github.com/Zireaelst/prophetia"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header
    
    print_step "Starting deployment process for $NETWORK..."
    
    # Run all steps
    check_prerequisites
    build_contracts
    
    # Ask if user wants to run tests
    echo ""
    print_warning "Do you want to run tests before deployment? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        run_tests
    fi
    
    # Deploy
    deploy_to_network
    save_deployment_info
    
    # Print next steps
    print_next_steps
    
    print_success "Deployment complete!"
}

# Run main function
main

################################################################################
# End of Script
################################################################################
