# Kaggle

**Live: https://www.kaggle.com/datasets/samrenkema/cryptopunks-daily-floor-price**
(created 2026-09-23 via the API, owner `samrenkema`).

**Still to do once, by hand:** the API creates datasets private and offers no visibility
switch. On the dataset page: **Settings → Visibility → Public**, and add
`docs/floor-history.png` as the cover image.

## Publishing a new version

```sh
cp data/*.csv kaggle/upload/
KAGGLE_API_TOKEN=<token> py -m kaggle datasets version -p kaggle/upload -m "Daily update"
```

Notes for whoever automates this:
- The current CLI authenticates with `KAGGLE_API_TOKEN` (the newer access token), not the
  old `KAGGLE_USERNAME` + `KAGGLE_KEY` pair.
- `dataset-metadata.json` must be UTF-8 **without** a BOM, or the CLI fails with
  "Expecting value: line 1 column 1".
- The `id` owner must be the Kaggle username (`samrenkema`), not a display name.
- Only the files in `kaggle/upload/` are uploaded, so this README never lands in the dataset.
- `cryptocurrency` is not a valid Kaggle tag; the accepted ones are in the metadata file.
