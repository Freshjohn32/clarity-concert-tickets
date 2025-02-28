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
    name: "Ensure past events cannot be created",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('ticket-manager', 'create-event', [
                types.uint(1),
                types.ascii("Past Concert"),
                types.uint(1609459200), // Jan 1, 2021
                types.bool(true)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(107);
    }
});

Clarinet.test({
    name: "Ensure tickets cannot be created with zero price",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('ticket-manager', 'create-event', [
                types.uint(1),
                types.ascii("Summer Concert 2024"),
                types.uint(1719792000),
                types.bool(true)
            ], deployer.address),
            Tx.contractCall('ticket-manager', 'create-ticket', [
                types.uint(1),
                types.uint(1),
                types.ascii("A1"),
                types.ascii("VIP"),
                types.uint(0),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        block.receipts[1].result.expectErr().expectUint(105);
    }
});

// [Additional test cases...]
