## Description

This PR introduces a comprehensive tenant improvement allowance management system built on the Stacks blockchain using Clarity smart contracts. The system provides transparent tracking of construction budgets, streamlined contractor payment coordination, and automated cost reconciliation for commercial property improvements.

## Overview

The tenant improvement manager contract creates an immutable ledger for managing tenant improvement (TI) budgets throughout the construction and renovation process. It addresses common challenges in commercial real estate including complex budget tracking, payment disputes, and difficult reconciliation of costs.

## Key Features

### Project Management
- **Create improvement projects** with defined tenant, property manager, and total allowance
- **Track project status** through active and closed states
- **Monitor spending** against approved allowances in real-time
- **Project lifecycle management** from initialization through closeout

### Budget Allocation & Tracking
- **Category-based budgeting** allowing allocation across different improvement types (e.g., HVAC, electrical, flooring)
- **Real-time budget utilization** tracking with percentage calculations
- **Remaining allowance monitoring** to prevent overspending
- **Budget vs. actual cost comparison** for each category

### Invoice & Payment Processing
- **Contractor invoice submission** with detailed descriptions and category assignment
- **Dual approval workflow** requiring both tenant and property manager approval
- **Payment authorization** with automatic allowance deduction
- **Payment history tracking** with complete audit trail
- **Budget enforcement** preventing payments that exceed available allowance

### Cost Reconciliation
- **Automated reconciliation** of project costs against budgets
- **Utilization rate calculations** showing percentage of allowance spent
- **Variance tracking** between allocated and spent amounts per category
- **Financial summary generation** for project reporting

### Documentation
- **Improvement documentation** capturing work details and final costs
- **Completion tracking** with block height timestamps
- **Multi-party documentation** allowing both managers and tenants to record details
- **Audit trail preservation** for compliance and dispute resolution

## Technical Implementation

### Data Structures

**Improvement Projects Map**
- Stores tenant, property manager, allowance amounts, spending, status, and creation time
- Indexed by unique project ID

**Contractor Invoices Map**
- Tracks invoice details, amounts, categories, approval status, and submission time
- Supports dual approval workflow (tenant + manager)

**Project Budgets Map**
- Category-level budget allocations and spending
- Composite key of project ID and category name

**Payments Map**
- Payment records with recipient, amount, timestamp, and method
- Links to invoice ID for complete traceability

**Improvement Documentation Map**
- Work descriptions, completion dates, final costs, and documenting party
- Composite key of project ID and document ID

### Security Features

- **Role-based authorization** - Functions restricted to appropriate parties (managers, tenants, contractors)
- **Budget validation** - Prevents spending beyond approved allowances
- **Approval requirements** - Dual approval workflow ensures mutual agreement
- **Status checks** - Prevents operations on closed or invalid projects
- **Immutable audit trail** - All transactions recorded on blockchain

### Error Handling

Comprehensive error codes for:
- Authorization failures (owner-only, unauthorized)
- Data validation (not found, invalid amount, invalid status)
- Business logic (insufficient allowance, already exists, already approved, not approved)

## Functions Implemented

### Read-Only Functions (6)
- `get-project-details` - Retrieve complete project information
- `get-invoice-details` - Get invoice data including approval status
- `get-remaining-allowance` - Calculate available budget balance
- `get-budget-for-category` - View category-specific budget details
- `get-payment-details` - Access payment transaction records
- `calculate-budget-utilization` - Compute spending percentage

### Public Functions (10)
- `create-improvement-project` - Initialize new TI project
- `allocate-budget-category` - Set budget for specific categories
- `submit-contractor-invoice` - Record contractor billing for work
- `approve-invoice-by-tenant` - Tenant approval of invoice
- `approve-invoice-by-manager` - Property manager approval of invoice
- `process-payment` - Execute approved payment from allowance
- `document-improvement` - Record completed work details
- `close-project` - Mark project as completed
- `reconcile-project-costs` - Generate financial summary report

## Benefits

### For Property Managers
- Streamlined allowance administration across portfolio
- Reduced manual reconciliation effort
- Real-time visibility into project finances
- Automated payment processing with built-in controls

### For Tenants
- Transparent budget tracking
- Confidence in contractor payment processing
- Easy verification of allowance utilization
- Complete financial records for accounting

### For Contractors
- Clear invoice submission process
- Transparent approval status tracking
- Predictable payment processing
- Reduced payment delays

## Testing

The contract includes:
- Syntax validation via `clarinet check`
- Proper Clarity type usage throughout
- Error handling for edge cases
- Authorization controls on all state-changing functions

## Code Quality

- **284 lines** of clean, well-commented Clarity code
- **Modular design** with separation of authorization, read-only, and public functions
- **Consistent naming** following Clarity best practices
- **Type safety** with appropriate use of uint, principal, string types
- **No external dependencies** - self-contained contract

## Future Enhancements

Potential improvements could include:
- Integration with actual STX payments for contractor disbursements
- Support for change orders and budget amendments
- Milestone-based payment releases
- Multiple currency support
- Automated notifications for approval requests
- Integration with off-chain document storage (IPFS)

## Related Documentation

See README.md for:
- System architecture overview
- Workflow descriptions
- Use case details
- Installation and setup instructions
