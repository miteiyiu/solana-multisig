# Solana Multisig Wallet Scripts

This repository contains three scripts for managing a Solana multisig wallet:

## 1. solana-multi-sig.sh
Initial setup script that creates a multisig wallet.

```bash
./solana-multi-sig.sh
```

This script will:
- Install required tools (Solana CLI & SPL Token CLI)
- Generate keypairs for owners
- Create a multisig wallet with specified threshold (2 signatures)
- Fund the first owner and multisig wallet with initial SOL

Configuration (in script):
- `THRESHOLD=2` - Number of required approvals
- `KEYS=("owner1.json" "owner2.json")` - Key files for owners
- `SIGNERS` - Array of signers (includes key files and additional addresses)
- `SOL_AMOUNT=0.005` - Initial funding for multisig
- `INIT_FUND=0.00005` - Initial funding for first owner

## 2. multisig_initiate.sh
Initiates transactions from the multisig wallet.

```bash
# Send SOL
./multisig_initiate.sh send-sol RECIPIENT_ADDRESS AMOUNT

# Send tokens
./multisig_initiate.sh send-token TOKEN_ACCOUNT_ADDRESS RECIPIENT_ADDRESS AMOUNT

# With custom multisig address
./multisig_initiate.sh --multisig MULTISIG_ADDRESS send-sol RECIPIENT_ADDRESS AMOUNT
```

Options:
- `--multisig ADDRESS` - Specify multisig address (if not in config)
- `--tx-file FILENAME` - Specify transaction file name (default: pending_tx.json)

## 3. multisig_approve.sh
Signs and submits multisig transactions.

```bash
# First owner signs
./multisig_approve.sh --key owner1.json

# Second owner signs and submits
./multisig_approve.sh --key owner2.json --submit
```

Options:
- `--key KEYFILE` - Specify key file to sign with (required)
- `--tx-file FILENAME` - Transaction file to sign (default: pending_tx.json)
- `--output FILENAME` - Output file for signed transaction (default: signed_tx.json)
- `--submit` - Submit transaction after signing

## Typical Workflow

1. Create multisig wallet:
```bash
./solana-multi-sig.sh
```

2. Initiate a transaction:
```bash
./multisig_initiate.sh send-sol ADDRESS 0.001
```

3. Get required signatures:
```bash
# First owner signs
./multisig_approve.sh --key owner1.json

# Second owner signs and submits
./multisig_approve.sh --key owner2.json --submit
```

## Notes
- All scripts use mainnet-beta by default
- Ensure you have enough SOL in the fee payer account
- Keep your key files secure and backed up
- The multisig address should be set in multisig_initiate.sh or provided via --multisig option
