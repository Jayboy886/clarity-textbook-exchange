[... previous tests unchanged ...]

Clarinet.test({
    name: "Cannot rent textbook with zero rental price",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('textbook-marketplace', 'list-textbook', [
                types.ascii("Computer Science 101"),
                types.ascii("1234567890123"),
                types.uint(100),
                types.uint(0),  // zero rental price
                types.uint(30)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(107);
    }
});

Clarinet.test({
    name: "Cannot purchase rented textbook",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        const wallet3 = accounts.get('wallet_3')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('textbook-marketplace', 'list-textbook', [
                types.ascii("Computer Science 101"),
                types.ascii("1234567890123"),
                types.uint(100),
                types.uint(20),
                types.uint(30)
            ], wallet1.address),
            Tx.contractCall('textbook-marketplace', 'rent-textbook', [
                types.uint(0)
            ], wallet2.address),
            Tx.contractCall('textbook-marketplace', 'purchase-textbook', [
                types.uint(0)
            ], wallet3.address)
        ]);
        
        block.receipts[2].result.expectErr().expectUint(104);
    }
});
