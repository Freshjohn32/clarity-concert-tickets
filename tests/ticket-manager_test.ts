import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged]

Clarinet.test({
    name: "Ensure refunds check contract balance correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // Setup: Create event and ticket
        let block = chain.mineBlock([
            Tx.contractCall('ticket-manager', 'create-event', [
                types.uint(1),
                types.ascii("Future Concert"),
                types.uint(1719792000),
                types.bool(true)
            ], deployer.address),
            Tx.contractCall('ticket-manager', 'create-ticket', [
                types.uint(1),
                types.uint(1),
                types.ascii("A1"),
                types.ascii("VIP"),
                types.uint(100),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        // Attempt refund
        let refundBlock = chain.mineBlock([
            Tx.contractCall('ticket-manager', 'request-refund', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        // Should fail due to insufficient contract balance
        refundBlock.receipts[0].result.expectErr().expectUint(110);
    }
});

// [Additional tests remain unchanged]
