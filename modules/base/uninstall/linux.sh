#!/usr/bin/env bash
# Base module uninstall script
# Only removes what we installed - checks for existing system tools first

set -e

echo "Uninstalling base module..."

# Note: We generally don't uninstall system packages as other things may depend on them
# This is a placeholder for cleanup if needed

echo "✅ Base module uninstalled (system packages retained)"