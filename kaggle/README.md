# Publishing to Kaggle

Kaggle needs your own account, so this is a one-time manual step (about 5 minutes).

1. Kaggle → Settings → **API → Create New Token**. Save the downloaded `kaggle.json` to
   `C:\Users\<you>\.kaggle\kaggle.json`.
2. `pip install kaggle`
3. In `dataset-metadata.json`, replace `KAGGLE_USERNAME` with your Kaggle username.
4. From the repo root:
   ```sh
   cp data/*.csv kaggle/
   kaggle datasets create -p kaggle
   ```
5. On the dataset page, upload `docs/floor-history.png` as the cover image.

Later updates: `cp data/*.csv kaggle/ && kaggle datasets version -p kaggle -m "Update"`.
To automate that, add `KAGGLE_USERNAME` and `KAGGLE_KEY` as repo secrets and a step to the
update workflow.
