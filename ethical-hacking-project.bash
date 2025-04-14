#!/bin/bash

# Check if the user provided a target URL
if [ -z "$1" ]; then
    echo "Usage: $0 <target_url>"
    exit 1
fi

TARGET_URL=$1
TARGET_IP=$(echo $TARGET_URL | sed 's|https\?://||' | cut -d/ -f1)

echo "Starting security assessment on: $TARGET_URL"
echo "Target IP/Domain: $TARGET_IP"

# Step 1: Perform an Nmap Scan
echo "Running Nmap scan..."
nmap -sV -A -T4 "$TARGET_IP" > nmap_scan_results.txt
echo "Nmap scan completed. Results saved in nmap_scan_results.txt."

# Step 2: Run OWASP ZAP Passive Scan (Requires ZAP Installed)
echo "Starting OWASP ZAP Passive Scan..."
zap-cli quick-scan --self-contained --start-options "-daemon" "$TARGET_URL" > zap_scan_results.txt
echo "OWASP ZAP Scan completed. Results saved in zap_scan_results.txt."

# Step 3: Test for SQL Injection using Curl
echo "Testing for SQL Injection vulnerabilities..."
SQL_TEST=$(curl -s -G --data-urlencode "id=1'" "$TARGET_URL" | grep "SQL syntax")

if [[ -n "$SQL_TEST" ]]; then
    echo "Possible SQL Injection vulnerability detected!"
    echo "Check SQL Injection manually at: $TARGET_URL?id=1'"
else
    echo "No obvious SQL Injection vulnerability detected."
fi

# Step 4: Test for XSS Vulnerabilities
echo "Testing for XSS vulnerabilities..."
XSS_TEST=$(curl -s -G --data-urlencode "q=<script>alert('XSS')</script>" "$TARGET_URL" | grep "<script>alert('XSS')</script>")

if [[ -n "$XSS_TEST" ]]; then
    echo "Potential XSS vulnerability detected!"
else
    echo "No obvious XSS vulnerability detected."
fi

echo "Vulnerability scan completed."
echo "Check the generated reports: nmap_scan_results.txt, zap_scan_results.txt"
