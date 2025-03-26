#!/bin/bash

# Recreate Existing Multisig Account Script

# Predefined Multisig Account Address
MULTISIG_ACCOUNT="accout maybe from testnet"

# Define Owner Keypaths
OWNER1_KEYPAIR="$HOME/owner1.json"
OWNER2_KEYPAIR="$HOME/owner2.json"
ADDITIONAL_OWNER="other owner"

# Function to verify network
check_network() {
    CURRENT_NETWORK=$(solana config get | grep "RPC URL" | awk '{print $3}')
    echo "Current Solana Network: $CURRENT_NETWORK"
    
    read -p "Do you want to continue with this network? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        echo "Please set the correct network using 'solana config set --url <network_url>'"
        exit 1
    fi
}

# Function to get public keys of owners
get_owner_pubkeys() {
    OWNER1_PUBKEY=$(solana-keygen pubkey "$OWNER1_KEYPAIR")
    OWNER2_PUBKEY=$(solana-keygen pubkey "$OWNER2_KEYPAIR")
    
    echo "Owner 1 Public Key: $OWNER1_PUBKEY"
    echo "Owner 2 Public Key: $OWNER2_PUBKEY"
    echo "Additional Owner: $ADDITIONAL_OWNER"
}

# Function to create/recreate multisig account
recreate_multisig() {
    echo "Recreating Multisig Account..."
    
    # Create multisig with specific parameters
    solana multisig create \
        --m 2 \
        --multisig-account "$MULTISIG_ACCOUNT" \
        --owners "$OWNER1_PUBKEY" "$OWNER2_PUBKEY" "$ADDITIONAL_OWNER"
}

# Main script execution
main() {
    # Check current network
    check_network

    # Get owner public keys
    get_owner_pubkeys

    # Show confirmation details
    echo -e "\nMultisig Account Recreation Details:"
    echo "Multisig Account Address: $MULTISIG_ACCOUNT"
    echo "Multisig Threshold: 2 of 3"

    # Prompt for final confirmation
    read -p "Confirm multisig account recreation? (y/n): " FINAL_CONFIRM
    if [[ "$FINAL_CONFIRM" == "y" ]]; then
        recreate_multisig
    else
        echo "Multisig account recreation cancelled."
        exit 0
    fi
}

# Run the main function
main
