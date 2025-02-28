import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test adding new chore - owner only",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const child = accounts.get('wallet_1')!;

    // Test adding chore as owner
    let block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'add-chore',
        [types.ascii("Clean room"), types.uint(50), types.principal(child.address)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectUint(1);

    // Test adding chore as non-owner (should fail)
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'add-chore',
        [types.ascii("Clean room"), types.uint(50), types.principal(child.address)],
        child.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Test chore completion and approval workflow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const child = accounts.get('wallet_1')!;

    // Add chore
    let block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'add-chore',
        [types.ascii("Clean room"), types.uint(50), types.principal(child.address)],
        deployer.address
      )
    ]);

    // Complete chore as assigned child
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'complete-chore',
        [types.uint(1)],
        child.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // Approve chore as parent
    block = chain.mineBlock([
      Tx.contractCall('chore-vault', 'approve-chore',
        [types.uint(1)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // Verify reward balance
    let response = chain.callReadOnlyFn('chore-vault', 'get-balance',
      [types.principal(child.address)],
      deployer.address
    );
    response.result.expectOk().expectUint(50);
  }
});
