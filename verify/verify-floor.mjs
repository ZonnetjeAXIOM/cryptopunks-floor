// Checks PunkPrice's daily floor against the CryptoPunks contract itself, with no event
// replay involved: reads punksOfferedForSale for all 10,000 punks at the last block of a
// UTC day and takes the lowest public ask (onlySellTo unset, price above zero).
//
//   cd verify && npm install && node verify-floor.mjs 2024-01-11 2022-12-01
//
// Needs an archive RPC (historical state). The default public endpoint works but is
// rate-limited; set RPC_URL to use another. Multicall3 exists from block 14353601
// (March 2022), so earlier days cannot be checked this way.
//
// 2026-09-21: 24 of 24 days where PunkPrice and cryptopunks.app disagree matched
// PunkPrice exactly (see the README and punkprice.com/data#methodology).

import { createPublicClient, http, parseAbi } from 'viem';

const PUNKS = '0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb';
const MULTICALL3 = '0xcA11bde05977b3631167028862bE2a173976CA11';
const ZERO = '0x0000000000000000000000000000000000000000';
const abi = parseAbi([
  'function punksOfferedForSale(uint256) view returns (bool isForSale, uint256 punkIndex, address seller, uint256 minValue, address onlySellTo)',
]);
const client = createPublicClient({
  transport: http(process.env.RPC_URL || 'https://eth.drpc.org', { timeout: 60_000, retryCount: 5, retryDelay: 1_500 }),
});

// Last block with timestamp <= the final second of the UTC day, by binary search.
async function lastBlockOfDay(day) {
  const target = BigInt(Date.parse(`${day}T00:00:00Z`) / 1000 + 86399);
  let lo = 14353601n, hi = await client.getBlockNumber();
  while (lo < hi) {
    const mid = (lo + hi + 1n) / 2n;
    const { timestamp } = await client.getBlock({ blockNumber: mid });
    if (timestamp <= target) lo = mid; else hi = mid - 1n;
  }
  return lo;
}

async function contractFloor(blockNumber) {
  let best = null;
  for (let start = 0; start < 10000; start += 500) {
    const res = await client.multicall({
      blockNumber,
      multicallAddress: MULTICALL3,
      allowFailure: false,
      contracts: Array.from({ length: 500 }, (_, i) => ({
        address: PUNKS, abi, functionName: 'punksOfferedForSale', args: [BigInt(start + i)],
      })),
    });
    for (const [isForSale, idx, , minValue, onlySellTo] of res) {
      if (!isForSale || onlySellTo !== ZERO || minValue === 0n) continue;
      if (!best || minValue < best.wei) best = { wei: minValue, punk: Number(idx) };
    }
  }
  return best && { eth: Number(best.wei) / 1e18, punk: best.punk };
}

const days = process.argv.slice(2);
if (!days.length) {
  console.error('usage: node scripts/verify-floor.mjs YYYY-MM-DD [...]');
  process.exit(1);
}

const { data } = await (await fetch('https://punkprice.com/api/data/floor-history.json')).json();
const ours = new Map(data.map(r => [r.date, r.floor_eth]));
let mismatches = 0;
for (const day of days) {
  const block = await lastBlockOfDay(day);
  const truth = await contractFloor(block);
  const match = truth && Math.abs(truth.eth - ours.get(day)) < 1e-9;
  if (!match) mismatches++;
  console.log(`${day}  block ${block}  contract ${truth?.eth} ETH (punk #${truth?.punk})  PunkPrice ${ours.get(day)}  ${match ? 'MATCH' : 'MISMATCH'}`);
}
process.exit(mismatches ? 2 : 0);
