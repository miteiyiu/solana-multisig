#!/bin/bash

# Configuration
THRESHOLD=2   # Number of approvals required
KEYS=("owner1.json" "owner2.json")  # Key files for owners
SIGNERS=("${KEYS[@]}" "4yL2V1bp7eTzugnd5CjcJhT5jio9FHdUfaMnoZM8NiW3")  # Third signer is just an address
SOL_AMOUNT=0.005  # Initial funding amount for multisig
INIT_FUND=0.00005  # Initial funding for first owner
TOKEN_MINT_ADDRESS="TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"  # Replace with a real mint address

# Step 1: Install Solana CLI & SPL Token CLI (if not installed)
echo "Checking Solana CLI installation..."
if ! command -v solana &> /dev/null; then
    echo "Installing Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
fi

if ! command -v spl-token &> /dev/null; then
    echo "Installing SPL Token CLI..."
    cargo install spl-token-cli
fi

# Step 2: Generate keypairs (only for first two owners)
echo "Generating keypairs..."
for key in "${KEYS[@]}"; do
    solana-keygen new --outfile $key --no-bip39-passphrase
done

# Step 3: Fund the first owner account from the default Solana account
echo "Funding first owner (${KEYS[0]}) with $INIT_FUND SOL..."
solana transfer $(solana-keygen pubkey ${KEYS[0]}) $INIT_FUND --allow-unfunded-recipient

# Step 4: Create a multisig wallet with the third signer as an address
echo "Creating multisig account..."
MULTISIG_ADDRESS=$(spl-token create-multisig $THRESHOLD "${SIGNERS[@]}" --fee-payer "${SIGNERS[0]}" | grep -oP "Creating [0-9]/[0-9] multisig \K[a-zA-Z0-9]{32,}" || echo "")

echo $MULTISIG_ADDRESS
if [ -z "$MULTISIG_ADDRESS" ]; then
    echo "Error: Failed to create multisig account. Exiting."
    exit 1
fi
echo "Multisig Address: $MULTISIG_ADDRESS"

# Step 5: Fund the multisig wallet
echo "Funding multisig wallet..."
solana transfer $MULTISIG_ADDRESS $SOL_AMOUNT --from ${KEYS[0]} --fee-payer ${KEYS[0]} --allow-unfunded-recipient || {
    echo "Error: Failed to fund multisig wallet. Exiting."
    exit 1
}

echo "Setup complete! Use the multisig address: $MULTISIG_ADDRESS"
