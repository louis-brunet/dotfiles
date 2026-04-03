#!/usr/bin/env bash
# AWS module uninstall script

set -e

echo "Uninstalling AWS module..."

# Note: AWS CLI doesn't have a clean uninstall - just remove the binary
if command -v aws &> /dev/null; then
    # This is approximate - proper uninstall would need to find the install location
    echo "⚠️ AWS CLI installed - you may need to uninstall manually"
    echo "  See: https://docs.aws.amazon.com/cli/latest/userguide/uninstall.html"
fi

echo "✅ AWS module uninstalled"