import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that creating a pool works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Deploy token contracts (assuming you have token-x.clar and token-y.clar in your contracts folder)
    const tokenX = deployer.address + '.token-x';
    const tokenY = deployer.address + '.token-y';
    
    let block = chain.mineBlock([
      Tx.contractCall('token-x', 'mint', [types.uint(1000000), types.principal(wallet1.address)], deployer.address),
      Tx.contractCall('token-y', 'mint', [types.uint(1000000), types.principal(wallet1.address)], deployer.address),
      Tx.contractCall('dex', 'create-pool', [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(100000),
        types.uint(100000)
      ], wallet1.address)
    ]);
    
    assertEquals(block.receipts.length, 3);
    assertEquals(block.height, 2);
    block.receipts[2].result.expectOk().expectBool(true);
    
    // Check pool details
    const poolDetails = chain.callReadOnlyFn('dex', 'get-pool-details', [
      types.principal(tokenX),
      types.principal(tokenY)
    ], deployer.address);
    
    poolDetails.result.expectSome().expectTuple({
      'reserve-x': types.uint(100000),
      'reserve-y': types.uint(100000),
      'total-liquidity': types.uint(100000)
    });
  },
});

Clarinet.test({
  name: "Ensure that adding liquidity works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    const tokenX = deployer.address + '.token-x';
    const tokenY = deployer.address + '.token-y';
    
    // Create initial pool
    let block = chain.mineBlock([
      Tx.contractCall('token-x', 'mint', [types.uint(1000000), types.principal(wallet1.address)], deployer.address),
      Tx.contractCall('token-y', 'mint', [types.uint(1000000), types.principal(wallet1.address)], deployer.address),
      Tx.contractCall('dex', 'create-pool', [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(100000),
        types.uint(100000)
      ], wallet1.address)
    ]);
    
    // Add liquidity
    block = chain.mineBlock([
      Tx.contractCall('token-x', 'mint', [types.uint(50000), types.principal(wallet2.address)], deployer.address),
      Tx.contractCall('token-y', 'mint', [types.uint(50000), types.principal(wallet2.address)], deployer.address),
      Tx.contractCall('dex', 'add-liquidity', [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(50000),
        types.uint(49000)
      ], wallet2.address)
    ]);
    
    assertEquals(block.receipts.length, 3);
    assertEquals(block.height, 3);
    block.receipts[2].result.expectOk().expectUint(50000);
    
    // Check updated pool details
    const poolDetails = chain.callReadOnlyFn('dex', 'get-pool-details', [
      types.principal(tokenX),
      types.principal(tokenY)
    ], deployer.address);
    
    poolDetails.result.expectSome().expectTuple({
      'reserve-x': types.uint(150000),
      'reserve-y': types.uint(150000),
      'total-liquidity': types.uint(150000)
    });
  },
});

Clarinet.test({
  name: "Ensure that swapping tokens works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    const tokenX = deployer.address + '.token-x';
    const tokenY = deployer.address + '.token-y';
    
    // Create initial pool
    let block = chain.mineBlock([
      Tx.contractCall('token-x', 'mint', [types.uint(1000000), types.principal(wallet1.address)], deployer.address),
      Tx.contractCall('token-y', 'mint', [types.uint(1000000), types.principal(wallet1.address)], deployer.address),
      Tx.contractCall('dex', 'create-pool', [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(100000),
        types.uint(100000)
      ], wallet1.address)
    ]);
    
    // Perform swap
    block = chain.mineBlock([
      Tx.contractCall('token-x', 'mint', [types.uint(10000), types.principal(wallet2.address)], deployer.address),
      Tx.contractCall('dex', 'swap-x-for-y', [
        types.principal(tokenX),
        types.principal(tokenY),
        types.uint(10000),
        types.uint(9000)
      ], wallet2.address)
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.height, 3);
    block.receipts[1].result.expectOk();
    
    // Check updated pool details
    const poolDetails = chain.callReadOnlyFn('dex', 'get-pool-details', [
      types.principal(tokenX),
      types.principal(tokenY)
    ], deployer.address);
    
    const updatedPool = poolDetails.result.expectSome().expectTuple();
    assertEquals(updatedPool['reserve-x'], types.uint(110000));
    assertTrue(updatedPool['reserve-y'] < types.uint(100000));
  },
});
