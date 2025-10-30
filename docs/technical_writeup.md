# Food Information App – Technical Writeup

## 1. Summary of the Solution
This app lets users search foods and view nutrition using the USDA database through a FastAPI backend and a Flutter interface.

## 2. Architecture Overview
#### Flutter UI → FastAPI → USDA API
The backend acts as a secure proxy that validates input, forwards calls to the USDA API, normalizes nutrient fields that vary across USDA responses, and translates server or network issues into friendly errors. The frontend handles user input, async loading states, navigation, and clean display of nutrition data.

## 3. API Documentation (Backend)
### 3.1 Base URL
- `http://127.0.0.1:8000`

### 3.2 Endpoints

- `GET /health`
  - 200: `{ "status": "ok" }`

- `GET /search?query=<string>&page=<int>`  
  - Request params: `query` required, `page` optional default 1  
  - 200 Response:
    ```json
    {
      "foods": [{"fdcId": 123, "description": "APPLE, RAW"}],
      "totalHits": 42,
      "pageNumber": 1,
      "totalPages": 3
    }
    ```
  - Errors: 400 invalid query, 500 missing API key, 502 upstream failed

- `GET /food/{fdc_id}`
  - 200 Response:
    ```json
    {
      "fdcId": 123,
      "description": "APPLE, RAW",
      "nutrients": {
        "calories": 52.0, "protein": 0.26, "fat": 0.17, "carbs": 13.81, "fiber": 2.4
      }
    }
    ```
  - Errors: 404 not found, 500 missing API key, 502 upstream failed

## 4. Request and Response Examples

#### curl "http://127.0.0.1:8000/search?query=apple&page=1"
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

#### curl "http://127.0.0.1:8000/food/1102644"
```json
{
  "fdcId": 1102644,
  "description": "Apple, raw",
  "nutrients": {
    "calories": 52.0,
    "protein": 0.26,
    "fat": 0.17,
    "carbs": 13.81,
    "fiber": 2.4
  }
}
```


## 5. Error Handling Documentation
### Status,	Meaning and	            User Message
- 200	    Success : 	        Data loaded
- 400	    Bad query :   	    Enter a valid search term
- 404 	Food not found :	    Food not found
- 500 	Backend setup issue :	Internal server error
- 502 	USDA failed :         USDA service unavailable or internet issue

## 6. Setup Instructions
### 6.1 Backend
python3 -m venv venv

source venv/bin/activate

pip install -r requirements.txt

cp .env.example .env   # enter USDA key

uvicorn main:app --reload --port 8000

### 6.2 Frontend
- `flutter pub get`
- Set `ApiConfig.baseUrl` as per target device
- `flutter run -d <device>`

## 7. Tests and Manual QA
- Manual test checklist:
  - Health ok
  - Search returns results for “apple”
  - Details load for first `fdcId`
  - Invalid `fdcId` returns user friendly error
  - Backend stopped -> app shows clear error
- Screenshots:
  - [Food Search](assets/images/search.png)
  - [Nutrition Details](assets/images/detail.png)
  - [Backend not connected](assets/images/error.png)

## 8. Challenges and Solutions
- CORS issues solved by FastAPI middleware
- USDA nutrient field variations handled with mapping and fallback names
- Environment config mistake: wrong base URL

## 9. Potential Improvements
- In memory caching
- Pagination in UI
- Search history
- Offline mode with last good result cache

## Appendix
### Versions
- Python 3.x
- FastAPI 0.x
- Flutter 3.x
- Dart SDK 3.x

### Major Dependencies
- FastAPI
- Requests
- Pydantic
- Flutter http package
- Provider for state management
