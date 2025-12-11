#!/bin/bash

# Azure DevOps Certificate Generator
# This script generates OpenSSL certificates for Azure service principal authentication

set -e

echo "======================================"
echo "Azure Certificate Generation Script"
echo "======================================"
echo ""

# Configuration
CERT_DIR="./certs"
KEY_FILE="$CERT_DIR/service-principal-key.pem"
CERT_FILE="$CERT_DIR/service-principal-cert.pem"
COMBINED_FILE="$CERT_DIR/service-principal-combined.pem"
CER_FILE="$CERT_DIR/service-principal-cert.cer"
VALIDITY_DAYS=365

# Create directory for certificates
mkdir -p "$CERT_DIR"

# Get certificate details from user
read -p "Enter Common Name (CN) [default: azure-devops-sp]: " CN
CN=${CN:-azure-devops-sp}

read -p "Enter Organization (O) [default: MyOrg]: " ORG
ORG=${ORG:-MyOrg}

read -p "Enter Country Code (C) [default: US]: " COUNTRY
COUNTRY=${COUNTRY:-US}

read -p "Enter validity in days [default: 365]: " DAYS
VALIDITY_DAYS=${DAYS:-365}

echo ""
echo "Generating certificate with the following details:"
echo "  CN: $CN"
echo "  O: $ORG"
echo "  C: $COUNTRY"
echo "  Validity: $VALIDITY_DAYS days"
echo ""

# Generate private key and certificate
echo "Step 1: Generating private key and self-signed certificate..."
openssl req -x509 -newkey rsa:4096 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days "$VALIDITY_DAYS" \
    -nodes \
    -subj "/C=$COUNTRY/O=$ORG/CN=$CN"

if [ $? -eq 0 ]; then
    echo "✓ Certificate generated successfully"
else
    echo "✗ Failed to generate certificate"
    exit 1
fi

# Create combined certificate (cert + key) for Azure DevOps
echo ""
echo "Step 2: Creating combined certificate file for Azure DevOps..."
cat "$CERT_FILE" "$KEY_FILE" > "$COMBINED_FILE"
echo "✓ Combined certificate created"

# Convert to DER format for Azure Portal upload
echo ""
echo "Step 3: Converting to DER format for Azure Portal..."
openssl x509 -in "$CERT_FILE" -outform DER -out "$CER_FILE"
echo "✓ DER certificate created"

# Display certificate information
echo ""
echo "======================================"
echo "Certificate Details"
echo "======================================"
openssl x509 -in "$CERT_FILE" -noout -subject -issuer -dates

echo ""
echo "======================================"
echo "SHA-1 Thumbprint (for Azure)"
echo "======================================"
THUMBPRINT=$(openssl x509 -in "$CERT_FILE" -noout -fingerprint -sha1 | cut -d'=' -f2)
echo "$THUMBPRINT"

# Remove colons for Azure format
THUMBPRINT_NO_COLON=$(echo "$THUMBPRINT" | tr -d ':')
echo "Without colons: $THUMBPRINT_NO_COLON"

echo ""
echo "======================================"
echo "Files Generated"
echo "======================================"
echo "Private Key:           $KEY_FILE"
echo "Certificate (PEM):     $CERT_FILE"
echo "Combined (PEM):        $COMBINED_FILE  ← Use this for Azure DevOps"
echo "Certificate (DER):     $CER_FILE       ← Use this for Azure Portal"

echo ""
echo "======================================"
echo "Next Steps"
echo "======================================"
echo "1. Upload $CER_FILE to Azure Portal:"
echo "   Portal > Azure AD > App Registrations > Your App > Certificates & secrets"
echo ""
echo "2. Or use Azure CLI:"
echo "   az ad sp credential reset --id <APP_ID> --cert @$CERT_FILE --append"
echo ""
echo "3. For Azure DevOps Service Connection:"
echo "   Use $COMBINED_FILE (contains both cert and private key)"
echo ""
echo "4. Note the thumbprint: $THUMBPRINT_NO_COLON"
echo ""
echo "⚠️  SECURITY WARNING ⚠️"
echo "Keep $KEY_FILE and $COMBINED_FILE secure!"
echo "Never commit these files to version control!"
echo ""

# Create .gitignore if it doesn't exist
if [ ! -f "$CERT_DIR/.gitignore" ]; then
    cat > "$CERT_DIR/.gitignore" << EOF
# Ignore all certificate files
*.pem
*.key
*.cer
*.pfx
*.p12
EOF
    echo "✓ Created .gitignore in $CERT_DIR"
fi

echo "======================================"
echo "Certificate generation complete!"
echo "======================================"

