# Kaggle

**Live and public: https://www.kaggle.com/datasets/samrenkema/cryptopunks-daily-floor-price**
(created 2026-09-23 via the API, owner `samrenkema`; public, with cover image, since 2026-09-25).

## Daily versions

`.github/workflows/update-data.yml` publishes a new Kaggle version after every data commit
(and on every manual run), using the repo secret `KAGGLE_API_TOKEN`. By hand:

```sh
cp data/*.csv kaggle/upload/
KAGGLE_API_TOKEN=<token> py -m kaggle datasets version -p kaggle/upload -m "Daily update"
```

## Changing the metadata (title, descriptions, columns, provenance, frequency)

Edit `kaggle/dataset-metadata.json`, copy it to `kaggle/upload/`, then:

```sh
KAGGLE_API_TOKEN=<token> py -m kaggle datasets metadata samrenkema/cryptopunks-daily-floor-price --update -p kaggle
```

- The metadata update sends `isPrivate` as false when it is missing, so it can make the
  dataset public. It is public now, so that is harmless.
- It uploads a `dataset-cover-image.{png,jpg,webp}` next to the metadata file and crops it
  to a fixed 560x280 from the top-left. **Keep no such file in `kaggle/`**, or it replaces
  the cover set by hand on the site.
- The metadata update only accepts the licence's display name,
  `Attribution 4.0 International (CC BY 4.0)`. `datasets create`/`version` accepted `CC-BY-4.0`.
- `userSpecifiedSources` is the "Provenance" field; `expectedUpdateFrequency` takes `daily`.

## CLI notes

- The current CLI authenticates with `KAGGLE_API_TOKEN` (the newer access token), not the
  old `KAGGLE_USERNAME` + `KAGGLE_KEY` pair.
- `dataset-metadata.json` must be UTF-8 **without** a BOM, or the CLI fails with
  "Expecting value: line 1 column 1".
- The `id` owner must be the Kaggle username (`samrenkema`), not a display name.
- Only the files in `kaggle/upload/` are uploaded, so this README never lands in the dataset.
- `cryptocurrency` is not a valid Kaggle tag; the accepted ones are in the metadata file.

## Starter notebook

`kaggle/notebook/` is https://www.kaggle.com/code/samrenkema/cryptopunks-floor-quick-start
(public). Update it with `kaggle kernels push -p kaggle/notebook`. The API refuses (403) to
make a *private* notebook public, which is why the first publish was done by hand; pushing to
an already-public notebook with `is_private: false` works. Pushing `is_private: true` would
hide it again.
