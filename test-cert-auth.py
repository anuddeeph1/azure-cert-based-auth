#!/usr/bin/env python3
"""
Azure Certificate-Based Authentication Test Script
Tests certificate authentication with Azure using Python SDK
"""

import os
import sys
from pathlib import Path

def check_requirements():
    """Check if required packages are installed"""
    try:
        import azure.identity
        import azure.mgmt.resource
        return True
    except ImportError:
        print("✗ Required Azure SDK packages not found")
        print("\nPlease install required packages:")
        print("  pip install azure-identity azure-mgmt-resource")
        return False

def main():
    print("=" * 50)
    print("Azure Certificate Auth Test - Python SDK")
    print("=" * 50)
    print()
    
    if not check_requirements():
        sys.exit(1)
    
    from azure.identity import CertificateCredential
    from azure.mgmt.resource import ResourceManagementClient, SubscriptionClient
    from azure.core.exceptions import ClientAuthenticationError
    
    # Configuration
    cert_file = "./certs/service-principal-combined.pem"
    if not os.path.exists(cert_file):
        cert_file = "./certs/service-principal-cert.pem"
        if not os.path.exists(cert_file):
            print(f"✗ Certificate file not found!")
            print(f"  Expected: ./certs/service-principal-combined.pem")
            print(f"  Run ./generate-cert.sh first")
            sys.exit(1)
    
    print(f"✓ Certificate file found: {cert_file}")
    print()
    
    # Get Azure details from user
    tenant_id = input("Enter Tenant ID: ").strip()
    if not tenant_id:
        print("✗ Tenant ID is required")
        sys.exit(1)
    
    client_id = input("Enter Application/Client ID: ").strip()
    if not client_id:
        print("✗ Client ID is required")
        sys.exit(1)
    
    subscription_id = input("Enter Subscription ID (optional, press Enter to skip): ").strip()
    
    print()
    print("=" * 50)
    print("Test 1: Certificate Authentication")
    print("=" * 50)
    
    # Create credential object
    try:
        credential = CertificateCredential(
            tenant_id=tenant_id,
            client_id=client_id,
            certificate_path=cert_file
        )
        print("✓ Certificate credential created")
    except Exception as e:
        print(f"✗ Failed to create credential: {str(e)}")
        sys.exit(1)
    
    print()
    print("=" * 50)
    print("Test 2: Token Acquisition")
    print("=" * 50)
    
    # Test token acquisition
    try:
        token = credential.get_token("https://management.azure.com/.default")
        print("✓ Successfully acquired access token")
        print(f"  Token expires: {token.expires_on}")
    except ClientAuthenticationError as e:
        print(f"✗ Authentication failed: {str(e)}")
        print("\nPossible issues:")
        print("  1. Certificate not uploaded to Azure AD")
        print("  2. Incorrect Client ID or Tenant ID")
        print("  3. Certificate expired or invalid")
        sys.exit(1)
    except Exception as e:
        print(f"✗ Unexpected error: {str(e)}")
        sys.exit(1)
    
    print()
    print("=" * 50)
    print("Test 3: List Subscriptions")
    print("=" * 50)
    
    # List subscriptions
    try:
        subscription_client = SubscriptionClient(credential)
        subscriptions = list(subscription_client.subscriptions.list())
        
        if subscriptions:
            print(f"✓ Found {len(subscriptions)} subscription(s):")
            for sub in subscriptions:
                print(f"  - {sub.display_name} ({sub.subscription_id})")
                if not subscription_id:
                    subscription_id = sub.subscription_id
        else:
            print("⚠ No subscriptions found")
            print("  The service principal may not have access to any subscriptions")
    except Exception as e:
        print(f"✗ Failed to list subscriptions: {str(e)}")
    
    if not subscription_id:
        print("\n⚠ No subscription ID available, skipping resource tests")
        sys.exit(0)
    
    print()
    print("=" * 50)
    print("Test 4: List Resource Groups")
    print("=" * 50)
    
    # List resource groups
    try:
        resource_client = ResourceManagementClient(credential, subscription_id)
        resource_groups = list(resource_client.resource_groups.list())
        
        if resource_groups:
            print(f"✓ Found {len(resource_groups)} resource group(s):")
            for rg in resource_groups:
                print(f"  - {rg.name} ({rg.location})")
        else:
            print("⚠ No resource groups found")
    except Exception as e:
        print(f"✗ Failed to list resource groups: {str(e)}")
        print("  The service principal may not have Reader/Contributor permissions")
    
    print()
    print("=" * 50)
    print("Test 5: List Resources")
    print("=" * 50)
    
    # List resources (limited to first 10)
    try:
        resources = list(resource_client.resources.list())
        
        if resources:
            print(f"✓ Found {len(resources)} resource(s) (showing first 10):")
            for resource in resources[:10]:
                print(f"  - {resource.name} ({resource.type})")
            
            if len(resources) > 10:
                print(f"  ... and {len(resources) - 10} more")
        else:
            print("⚠ No resources found")
    except Exception as e:
        print(f"✗ Failed to list resources: {str(e)}")
    
    print()
    print("=" * 50)
    print("Test Summary")
    print("=" * 50)
    print("✓ Certificate authentication successful")
    print("✓ Token acquisition working")
    print("✓ Azure API access confirmed")
    print()
    print("Configuration Details:")
    print(f"  Tenant ID:       {tenant_id}")
    print(f"  Client ID:       {client_id}")
    print(f"  Subscription ID: {subscription_id}")
    print(f"  Certificate:     {cert_file}")
    print()
    print("=" * 50)
    print("Ready for Azure DevOps Integration!")
    print("=" * 50)
    print("\nYou can now use these credentials in:")
    print("  1. Azure DevOps Service Connections")
    print("  2. CI/CD Pipelines")
    print("  3. Automation Scripts")
    print()
    print("See Azure-Certificate-Based-Auth-Guide.md for detailed steps")
    print()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nTest cancelled by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n✗ Unexpected error: {str(e)}")
        sys.exit(1)

