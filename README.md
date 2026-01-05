# Escrow- Two Party handshake Escrow (ETH)
A Secure decentralized Escrow which holds ETH from a buyer and releases it to a seller only after seller delivery and buyer acceptance, with timeout based failure resolution

## User Actions
### Buyer
1. Wants refund if seller doesn't deliver
2. Might stall acceptance to grief seller

### Seller
1. Wants payment
2. Might claim delivery without delivering

## Normal Path
1. Buyer deposits ETH
2. Seller confirms delivery
3. Buyer accepts
4. Funds goes to seller

## Failure Path
1. If seller never confirms- buyer refunds after deadline
2. If buyer never accepts-  buyer refunds after deadline

## Rules
1. Buyer funds escrow
2. Seller cannot withdraw directly
3. Buyer cannot accept without seller confirms
4. Refund only after timeout
5. Funds move exactly once
6. No owner