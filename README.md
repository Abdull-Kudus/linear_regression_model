# Informal Business Revenue Estimator (Nigeria)

## Mission and problem

My mission is to build practical technology that makes complex systems work better for people across Africa.
Most small Nigerian businesses have no bank records, so lenders can't tell what they could repay and turn them down.
This project estimates a business's monthly revenue per worker from 12 facts the owner can answer in two minutes,
so a lender can size a loan the business can actually repay.

## Dataset

**World Bank LSMS: Household Business Indicators for Sub-Saharan Africa 2014-2024** (AFR_2014-2024_LSMS-HBI_v01_M)
<https://microdata.worldbank.org/index.php/catalog/8591>

- Real household survey data. I use the Nigeria rows, which come from the General Household Survey Panel run by
  Nigeria's National Bureau of Statistics with the World Bank (2018/19 and 2023/24 rounds).
- 7,355 Nigerian businesses, 7,282 after cleaning.
- 12 inputs: 3 categorical (state, sector, urban or rural) and 9 numeric (survey year, workers, business age, owner
  education, owner age group, owner gender, separate premises, sells to firms or government, credit difficulty).
- Target: monthly revenue per worker in PPP-adjusted US dollars (a continuous number).
- The licence does not allow the data to be shared again, so the CSV is not in this repository. To rerun the
  notebook, download `LSMS_HBI_BUSINESS.csv` from the link above into `summative/linear_regression/data/`.

## API (Swagger UI)

<https://ng-business-revenue-api.onrender.com/docs>

The API runs on Render's free plan. If nobody has used it for 15 minutes it goes to sleep, and the first request
can take up to a minute while it wakes up.

| Route | What it does |
|---|---|
| `POST /predict` | Takes the 12 inputs as JSON and returns the estimated monthly revenue per worker and for the whole business. |
| `POST /retrain` | Takes a CSV of new businesses and retrains the model. `/predict` uses the new model straight away. |
| `GET /docs` | Swagger UI for trying both routes in the browser. |

To try a prediction, open `POST /predict`, click **Try it out**, keep the example body and click **Execute**:

```json
{
  "state": "Lagos", "sector": "Services", "urban": "Urban", "survey_year": 2024,
  "total_workers": 2, "business_age": 6, "owner_education_years": 12, "owner_age_group": 3,
  "owner_female": 1, "separate_premises": 1, "sells_to_firms_or_govt": 0, "credit_difficulty": 1
}
```

Every input is checked before the model runs. A wrong type (for example `"total_workers": "two"`), a missing
field or a value out of range (for example `"survey_year": 2030`) returns a `422` error that names the field,
and no prediction is made.

| Input | Allowed values |
|---|---|
| `state` | One of the 37 states, including FCT (for example `Lagos`, `Kano`, `Akwa Ibom`) |
| `sector` | `Agriculture`, `Manufacturing`, `Other`, `Services` |
| `urban` | `Urban`, `Rural` |
| `survey_year` | 2019 to 2024 |
| `total_workers` | 1 to 56, including the owner |
| `business_age` | 1 to 77 years |
| `owner_education_years` | 0 to 18 |
| `owner_age_group` | 1 = 15-24, 2 = 25-34, 3 = 35-44, 4 = 45-54, 5 = 55-64, 6 = 65+ |
| `owner_female`, `separate_premises`, `sells_to_firms_or_govt`, `credit_difficulty` | 1 = yes, 0 = no |

A `/retrain` CSV needs the same 12 columns plus `revenue_per_worker` (the real monthly revenue per worker in PPP
US dollars). Each row is checked with the same rules as `/predict`.

## Video demo

<https://youtu.be/og9QVd1cM2o>

## How to run the mobile app

The app is in `summative/FlutterApp`. It runs on an Android emulator or a real Android phone and calls the live
API above, so you need an internet connection.

**You need**

- [Flutter](https://docs.flutter.dev/get-started/install) 3.47 or newer (check with `flutter --version`)
- Android Studio with an Android emulator, or an Android phone with USB debugging turned on

**Steps**

1. Clone the repository and go into the app folder:

   ```bash
   git clone https://github.com/Abdull-Kudus/linear_regression_model.git
   cd linear_regression_model/summative/FlutterApp
   ```

2. Install the packages:

   ```bash
   flutter pub get
   ```

3. Start an emulator from Android Studio (Device Manager, then the play button), or plug in your phone. Check
   that Flutter can see it:

   ```bash
   flutter devices
   ```

4. Run the app:

   ```bash
   flutter run
   ```

   If more than one device is listed, add `-d` and the device id, for example `flutter run -d emulator-5554`.

**Using the app**

1. Fill in the 12 fields, or tap **Fill example** to load a sample business.
2. Tap **Predict**. The estimate appears in the box at the bottom. The first prediction can take up to a minute
   if the server was asleep.
3. If a field is empty, not a number or out of range, the app shows the error and does not send the request.

**Run the app's tests**

```bash
flutter test
```

## Run the API on your own computer (optional)

The API uses [uv](https://docs.astral.sh/uv/) and Python 3.13.

```bash
cd summative
uv sync
cd API
uv run uvicorn prediction:app --reload
```

Then open <http://127.0.0.1:8000/docs>. `/predict` works straight away because the saved model
(`best_model.pkl`) is in the repository. `/retrain` also needs the cleaned training and test rows, which the
notebook writes to `summative/linear_regression/data/` after you download the dataset.

## Repository structure

```
linear_regression_model/
├── README.md
└── summative/
    ├── pyproject.toml, uv.lock     # Python dependencies (uv)
    ├── linear_regression/
    │   └── multivariate.ipynb      # data analysis, 4 models, comparison, best model saved
    ├── API/
    │   ├── prediction.py           # FastAPI app: /predict, /retrain, CORS
    │   ├── best_model.pkl          # saved random forest pipeline
    │   └── requirements.txt        # exported from uv for Render
    └── FlutterApp/                 # one-page Flutter app
```
