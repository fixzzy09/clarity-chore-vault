import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test contract management functions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const child = accounts.get('wallet_1')!;

    // Test pause contract
    let block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'pause-contract',
        [],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // Test adding chore while paused (should fail)
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'add-chore',
        [types.ascii("Clean room"), types.uint(50), types.principal(child.address), types.uint(100)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(105);

    // Test unpause
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'unpause-contract',
        [],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});

// Original tests remain unchanged...
