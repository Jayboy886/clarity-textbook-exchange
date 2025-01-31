import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can list a new textbook",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('textbook-marketplace', 'list-textbook', [
                types.ascii("Computer Science 101"),
                types.ascii("1234567890123"),
                types.uint(100)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
    }
});

Clarinet.test({
    name: "Can purchase a listed textbook",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('textbook-marketplace', 'list-textbook', [
                types.ascii("Computer Science 101"),
                types.ascii("1234567890123"),
                types.uint(100)
            ], wallet1.address),
            Tx.contractCall('textbook-marketplace', 'purchase-textbook', [
                types.uint(0)
            ], wallet2.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can remove a listing by owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('textbook-marketplace', 'list-textbook', [
                types.ascii("Computer Science 101"),
                types.ascii("1234567890123"),
                types.uint(100)
            ], wallet1.address),
            Tx.contractCall('textbook-marketplace', 'remove-listing', [
                types.uint(0)
            ], wallet1.address)
        ]);
        
        block.receipts[1].result.expectOk().expectBool(true);
    }
});
