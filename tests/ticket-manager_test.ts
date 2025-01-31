import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure that tickets can be created by owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('ticket-manager', 'create-ticket', [
                types.uint(1),
                types.ascii("A1"),
                types.ascii("VIP"),
                types.uint(100),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Ensure tickets can be transferred by owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('ticket-manager', 'create-ticket', [
                types.uint(1),
                types.ascii("A1"),
                types.ascii("VIP"),
                types.uint(100),
                types.principal(wallet1.address)
            ], deployer.address),
            Tx.contractCall('ticket-manager', 'transfer-ticket', [
                types.uint(1),
                types.principal(wallet2.address)
            ], wallet1.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Ensure tickets can be used by owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('ticket-manager', 'create-ticket', [
                types.uint(1),
                types.ascii("A1"),
                types.ascii("VIP"),
                types.uint(100),
                types.principal(wallet1.address)
            ], deployer.address),
            Tx.contractCall('ticket-manager', 'use-ticket', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});
