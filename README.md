# Commercial Property Tenant Improvement Allowance

A blockchain-based lease management platform for tracking construction budgets, coordinating contractor payments, and reconciling improvement costs in commercial real estate.

## Overview

The Tenant Improvement Allowance system provides a transparent, immutable ledger for managing tenant improvement (TI) budgets throughout the construction and renovation process. This smart contract solution streamlines the complex workflow of approving contractor invoices, coordinating payments, and ensuring that improvement costs remain within the negotiated allowance limits.

## Key Features

### Budget Management
- **Allowance Tracking**: Monitor total approved TI budgets per lease
- **Real-time Balance**: Track remaining allowance throughout construction
- **Multi-tenant Support**: Manage multiple tenant improvement projects simultaneously
- **Budget Allocation**: Define spending categories and limits

### Contractor Payment Processing
- **Invoice Submission**: Contractors can submit detailed invoices for work completed
- **Multi-stage Approval**: Property managers review and approve payment requests
- **Payment Coordination**: Execute approved payments from allowance budgets
- **Payment History**: Maintain complete audit trail of all disbursements

### Cost Reconciliation
- **Expense Tracking**: Categorize and track all improvement costs
- **Budget vs. Actual**: Compare planned allowances with actual expenditures
- **Overage Management**: Flag and handle budget overages
- **Final Reconciliation**: Close-out process for completed projects

### Documentation & Compliance
- **Improvement Documentation**: Record details of all completed work
- **Lien Waivers**: Track contractor lien waiver submissions
- **Compliance Verification**: Ensure work meets lease agreement terms
- **Audit Trail**: Immutable record of all transactions and approvals

## Business Use Cases

### Property Owners & Managers
- Streamline TI allowance administration across portfolio
- Reduce manual reconciliation and paperwork
- Improve cash flow visibility and forecasting
- Minimize disputes through transparent processes

### Tenants
- Track improvement budget utilization in real-time
- Ensure contractors are paid promptly
- Maintain records for their own accounting
- Verify compliance with lease terms

### Contractors
- Submit invoices with supporting documentation
- Track payment status transparently
- Reduce payment delays
- Maintain records for project portfolio

## System Architecture

### Smart Contract Components

**Tenant Improvement Manager Contract**
- Allowance initialization and budget setup
- Contractor invoice processing and approval workflow
- Payment coordination and execution
- Cost reconciliation and reporting
- Documentation management
- Project completion and close-out

### Data Structures

- **Improvement Projects**: Lease details, allowance amounts, status
- **Invoices**: Line items, amounts, supporting documentation
- **Payments**: Payment records with approval chain
- **Reconciliation**: Budget vs. actual comparisons
- **Documentation**: Improvement descriptions, photos, compliance records

## Workflow

1. **Project Initialization**: Property manager creates TI project with approved allowance
2. **Budget Setup**: Allocate allowance across improvement categories
3. **Invoice Submission**: Contractors submit invoices for work completed
4. **Review & Approval**: Property manager reviews and approves invoices
5. **Payment Processing**: Execute approved payments from allowance budget
6. **Progress Tracking**: Monitor budget utilization throughout construction
7. **Documentation**: Record completed improvements with details
8. **Final Reconciliation**: Compare final costs to allowance, handle overages
9. **Project Closeout**: Complete final documentation and close project

## Benefits

- **Transparency**: All parties can view project status and payment history
- **Efficiency**: Automated workflows reduce administrative burden
- **Accuracy**: Eliminate manual calculation errors in reconciliation
- **Compliance**: Ensure adherence to lease agreement terms
- **Auditability**: Complete, immutable record of all transactions
- **Dispute Resolution**: Clear documentation reduces conflicts
- **Cash Flow Management**: Better visibility enables improved forecasting

## Technical Specifications

- **Blockchain**: Stacks blockchain using Clarity smart contracts
- **Language**: Clarity (version 2.0)
- **Token Support**: STX for payments and transaction fees
- **Access Control**: Role-based permissions (property manager, tenant, contractor)
- **Data Storage**: On-chain for critical data, off-chain references for documents

## Security Features

- **Authorization Controls**: Function-level access restrictions
- **Budget Validation**: Prevents overspending beyond approved allowances
- **Approval Requirements**: Multi-step verification for payments
- **Immutable Records**: Tamper-proof transaction history
- **Audit Logging**: Complete tracking of all system actions

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Basic understanding of Clarity and smart contracts

### Installation
```bash
# Clone the repository
git clone <repository-url>

# Navigate to project directory
cd Commercial-property-tenant-improvement-allowance

# Install dependencies
npm install

# Run tests
clarinet test

# Check contracts
clarinet check
```

### Development
```bash
# Start Clarinet console
clarinet console

# Deploy to testnet
clarinet deploy --testnet
```

## Project Structure

```
Commercial-property-tenant-improvement-allowance/
├── contracts/
│   └── tenant-improvement-manager.clar
├── tests/
│   └── tenant-improvement-manager.test.ts
├── settings/
│   ├── Devnet.toml
│   ├── Testnet.toml
│   └── Mainnet.toml
├── Clarinet.toml
├── package.json
└── README.md
```

## Testing

The contract includes comprehensive test coverage for:
- Project initialization and budget setup
- Invoice submission and validation
- Approval workflows
- Payment processing
- Budget enforcement
- Reconciliation logic
- Error handling and edge cases

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please submit pull requests or open issues for bugs and feature requests.

## Support

For questions or support, please open an issue in the repository or contact the development team.

## Version History

- **v1.0.0**: Initial release with core TI allowance management functionality
