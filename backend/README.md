## Food Info Backend using FastAPI

A small FastAPI service that acts as middleware between the Flutter app and the USDA FoodData Central API. It exposes two endpoints: a search endpoint and a details endpoint that returns key nutrients.

## Project structure

```
backend/
  main.py
  requirements.txt
  .env.example
  README.md
```

## Prerequisites

* Python 3.8 or newer
* A USDA FoodData Central API key
* pip

## Setup

1. Create and activate a virtual environment

   ```bash
   cd backend
   python -m venv venv
   # macOS or Linux
   source venv/bin/activate
   ```

2. Install dependencies

   ```bash
   pip install -r requirements.txt
   ```

3. Create `.env` from the example and add your key

   ```bash
   cp .env.example .env
   # edit .env and set:
   # USDA_API_KEY=YOUR_REAL_KEY
   ```

## Run

```bash
uvicorn main:app --reload --port 8000
```

* Swagger UI: `http://127.0.0.1:8000/docs`
* ReDoc: `http://127.0.0.1:8000/redoc`
* Health: `http://127.0.0.1:8000/health`

## Endpoints

### GET /health

Returns basic status.

```json
{ "status": "ok" }
```

### GET /search

Parameters

* `query` required string
* `page` optional integer default 1
  Page size is fixed at 20.

Example

```bash
curl "http://127.0.0.1:8000/search?query=apple&page=1"
```

Response

```json
{
  "foods": [
    {
      "fdcId": 454004,
      "description": "APPLE"
    },
    ,
    {
      "fdcId": 168816,
      "description": "Fruit butters, apple"
    }
  ],
  "totalHits": 26790,
  "pageNumber": 1,
  "totalPages": 1340
}
```

### GET /food/{fdc_id}

Returns key nutrients for a food.

Example

```bash
curl "http://127.0.0.1:8000/food/2057649"
```

Response

```json
{
  "fdcId": 2057649,
  "description": "DIYA, WHOLE MOONG",
  "nutrients": {
    "calories": 350.0,
    "protein": 24.0,
    "fat": 0.0,
    "carbs": 63.0,
    "fiber": 16.0
  }
}
```

## Error handling

* 500 Server misconfigured if API key missing
* 502 Upstream request failed if USDA is unreachable
* 404 Food not found for invalid `fdcId`
* Other HTTP codes from USDA are passed through where applicable

## CORS

CORS is open to all origins during development. We need to tighten this in production.

## Configuration

* Environment variables from `.env`

  * `USDA_API_KEY`


## Troubleshooting

* Search returns 500 missing API key
* Ensure `.env` contains `USDA_API_KEY` and process was started from `backend` folder
* 502 Upstream request failed
* Retry then check network connectivity
* Confirm USDA endpoints are reachable from your machine
* 404 on details
* The `fdcId` does not exist in USDA data or is not accessible
* Seeing CORS errors in a browser
* The app uses `allow_origins=["*"]` in development. If you changed it, recheck your origin settings
