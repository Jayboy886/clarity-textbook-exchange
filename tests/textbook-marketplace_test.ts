// [Previous tests unchanged...]

Clarinet.test({
    name: "Cannot list textbook with invalid prices or duration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Test zero purchase price
        let block = chain.mineBlock([
            Tx.contractCall('textbook-marketplace', 'list-textbook', [
                types.ascii("Computer Science 101"),
                types.ascii("1234567890123"),
                types.uint(0),  // zero purchase price
                types.uint(10),
                types.uint(30)
            ], wallet1.address)
        ]);
        block.receipts[0].result.expectErr().expectUint(108);

        // Test rental price higher than purchase price
        block = chain.mineBlock([
            Tx.contractCall('textbook-marketplace', 'list-textbook', [
                types.ascii("Computer Science 101"),
                types.ascii("1234567890123"),
                types.uint(100),
                types.uint(200),  // rental price > purchase price
                types.uint(30)
            ], wallet1.address)
        ]);
        block.receipts[0].result.expectErr().expectUint(107);

        // Test zero rental duration
        block = chain.mineBlock([
            Tx.contractCall('textbook-marketplace', 'list-textbook', [
                types.ascii("Computer Science 101"),
                types.ascii("1234567890123"),
                types.uint(100),
                types.uint(50),
                types.uint(0)  // zero rental duration
            ], wallet1.address)
        ]);
        block.receipts[0].result.expectErr().expectUint(109);
    }
});

// [Remaining tests unchanged...]
