# Publishing on Dune

Dune needs your own account; the query itself is ready.

1. dune.com → **New → Query** → paste [`cryptopunks-daily-floor.sql`](cryptopunks-daily-floor.sql) → Run.
   It reads raw `ethereum.logs`, so it doesn't depend on any decoded table. Expect a
   minute or two on the first run.
   - Title: **CryptoPunks daily floor (on-chain, since 2017)**
   - Sanity check: the last rows should match https://punkprice.com/api/data/floor-history.csv
2. Add a visualisation: **Line chart**, x = `day`, y = `floor_eth`, y-axis **logarithmic**.
3. **New → Dashboard** "CryptoPunks floor, every day since 2017". Add the chart and a text widget:

```markdown
**The CryptoPunks floor, recomputed from the contract.** Lowest *public* ask on the
CryptoPunks marketplace contract at the end of each UTC day, since 23 June 2017. Offers
reserved for one buyer are excluded. Every offer lives until the next event for that punk.

Chart, CSV/JSON downloads and methodology: [punkprice.com/data](https://punkprice.com/data?utm_source=dune)
Source + verification: [github.com/ZonnetjeAXIOM/cryptopunks-floor](https://github.com/ZonnetjeAXIOM/cryptopunks-floor)
```

4. Set the query to refresh daily (Query → Schedule), if your plan allows it.

The SQL was checked by running the same logic over the full event log: it reproduces all
3,378 published days exactly.
