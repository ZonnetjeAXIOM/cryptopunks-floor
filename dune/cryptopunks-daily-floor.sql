-- CryptoPunks daily floor, recomputed from the CryptoPunks marketplace contract's own events.
-- Same definition as punkprice.com/data: the lowest PUBLIC ask standing at the end of each
-- UTC day (23:59:59). Offers reserved for one buyer (toAddress set) are excluded, because
-- nobody else can take them. Any later event for the same punk (a new offer, a withdrawal,
-- a sale or a transfer) ends the previous offer, exactly as the contract does.
--
-- Reads raw ethereum.logs, so it does not depend on any decoded table.
-- Source and CSV: https://punkprice.com/data (CC BY 4.0)

WITH ev AS (
  SELECT
    block_time,
    block_number,
    index AS log_index,
    topic0,
    CASE
      WHEN topic0 = 0x05af636b70da6819000c49f85b21fa82081c632069bb626f30932034099107d8  -- PunkTransfer: punkIndex is in data
        THEN bytearray_to_uint256(bytearray_substring(data, 1, 32))
      ELSE bytearray_to_uint256(topic1)
    END AS punk,
    CASE WHEN topic0 = 0x3c7b682d5da98001a9b8cbda6c647d2c63d698a4184fd1d55e2ce7b66f5d21eb
      THEN bytearray_to_uint256(bytearray_substring(data, 1, 32)) END AS min_value_wei,
    CASE WHEN topic0 = 0x3c7b682d5da98001a9b8cbda6c647d2c63d698a4184fd1d55e2ce7b66f5d21eb
      THEN topic2 <> 0x0000000000000000000000000000000000000000000000000000000000000000 END AS is_private
  FROM ethereum.logs
  WHERE contract_address = 0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb
    AND block_number >= 3914495
    AND topic0 IN (
      0x3c7b682d5da98001a9b8cbda6c647d2c63d698a4184fd1d55e2ce7b66f5d21eb,  -- PunkOffered
      0xb0e0a660b4e50f26f0b7ce75c24655fc76cc66e3334a54ff410277229fa10bd4,  -- PunkNoLongerForSale
      0x58e5d5a525e3b40bc15abaa38b5882678db1ee68befd2f60bafe3a7fd06db9e3,  -- PunkBought
      0x05af636b70da6819000c49f85b21fa82081c632069bb626f30932034099107d8   -- PunkTransfer
    )
),

-- Each offer lives until the next event for the same punk.
lived AS (
  SELECT
    *,
    LEAD(block_time) OVER (PARTITION BY punk ORDER BY block_number, log_index) AS ended_at
  FROM ev
),

-- An offer counts for day D if it was made before the end of D and was still open at
-- the end of D, i.e. D runs from date(made) to date(ended) - 1.
asks AS (
  SELECT
    punk,
    CAST(min_value_wei AS DOUBLE) / 1e18 AS price_eth,
    CAST(block_time AS DATE) AS first_day,
    COALESCE(CAST(ended_at AS DATE) - INTERVAL '1' DAY, CURRENT_DATE) AS last_day
  FROM lived
  WHERE topic0 = 0x3c7b682d5da98001a9b8cbda6c647d2c63d698a4184fd1d55e2ce7b66f5d21eb
    AND NOT is_private
    AND min_value_wei > UINT256 '0'
)

SELECT
  day,
  MIN(price_eth) AS floor_eth,
  MIN_BY(punk, price_eth) AS floor_punk_index,
  COUNT(*) AS public_asks
FROM asks
CROSS JOIN UNNEST(sequence(first_day, last_day, INTERVAL '1' DAY)) AS t(day)
WHERE last_day >= first_day
GROUP BY 1
ORDER BY 1
