"""Food Info Backend using FastAPI

This service wraps a subset of the USDA FoodData Central API and exposes
a minimal backend for the assignment.

Features
- /health lightweight health probe
- /search to search for foods by name with paging
- /food/{fdc_id} to fetch core nutrient facts for a single FDC item

Notes
- Reads USDA_API_KEY from environment. Use a local .env file for development.
- CORS is enabled for all origins to simplify local Flutter dev.
- Exceptions map upstream USDA errors into sensible HTTP status codes.
- Response models are typed with Pydantic for stable, documented contracts.

"""

# main.py
from typing import List, Optional, Dict, Any
import os
import requests
from fastapi import FastAPI, HTTPException, Query, Path
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from dotenv import load_dotenv

# App setup, env, CORS

load_dotenv()  # loads .env sitting next to this file
API_KEY = os.getenv("USDA_API_KEY")

app = FastAPI(
    title="Food Info Backend (FastAPI)",
    description="Middleware for USDA FoodData Central API",
    version="1.0.0",
)

# Open up CORS for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models (Pydantic)

class FoodItem(BaseModel):
    """Pydantic model for FoodItem."""

    fdcId: int = Field(..., description="USDA FoodData Central ID")
    description: str = Field(..., description="Food description")

class SearchResponse(BaseModel):
    """Pydantic model for SearchResponse."""

    foods: List[FoodItem]
    totalHits: int
    pageNumber: int
    totalPages: int

class Nutrients(BaseModel):
    """Pydantic model for Nutrients."""

    calories: Optional[float] = None
    protein: Optional[float] = None
    fat: Optional[float] = None
    carbs: Optional[float] = None
    fiber: Optional[float] = None

class FoodDetails(BaseModel):
    """Pydantic model for FoodDetails."""

    fdcId: int
    description: str
    nutrients: Nutrients

# Utilities

SEARCH_URL = "https://api.nal.usda.gov/fdc/v1/foods/search"
DETAIL_URL_TMPL = "https://api.nal.usda.gov/fdc/v1/food/{fdc_id}"

# Nutrient IDs commonly used by FDC (fallback if names differ):
# 208 Energy (kcal), 203 Protein (g), 204 Total lipid (fat) (g),
# 205 Carbohydrate, by difference (g), 291 Fiber, total dietary (g)
KEY_NUTRIENT_IDS = {
    208: "calories",
    203: "protein",
    204: "fat",
    205: "carbs",
    291: "fiber",
}

def _ensure_api_key():
    if not API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Server misconfigured: USDA_API_KEY missing. Add it to .env",
        )

def _simplify_foods(items: List[Dict[str, Any]]) -> List[FoodItem]:
    simplified: List[FoodItem] = []
    for it in items or []:
        fdc_id = it.get("fdcId")
        desc = it.get("description") or it.get("lowercaseDescription") or "Unknown item"
        if isinstance(fdc_id, int):  # ensure valid
            simplified.append(FoodItem(fdcId=fdc_id, description=str(desc)))
    return simplified

def _extract_key_nutrients(food_json: Dict[str, Any]) -> Nutrients:
    """
    Extract calories, protein, fat, carbs, fiber.
    Tries nutrient IDs first (robust), then name-based fallbacks.
    """
    found: Dict[str, Optional[float]] = {
        "calories": None,
        "protein": None,
        "fat": None,
        "carbs": None,
        "fiber": None,
    }

    for n in food_json.get("foodNutrients", []) or []:
        # Newer responses: n["nutrient"] is a dict with id/name/number, value in n["amount"]
        # Older responses: name may be in n["nutrientName"]
        nut = n.get("nutrient") or {}
        amount = n.get("amount")
        if amount is None:
            continue

        # Try by ID first
        nid = nut.get("id")
        if isinstance(nid, int) and nid in KEY_NUTRIENT_IDS:
            found[KEY_NUTRIENT_IDS[nid]] = float(amount)
            continue

        # Fallback by name string
        name = (nut.get("name") or n.get("nutrientName") or "").lower()
        if not name:
            continue
        if ("energy" in name) or ("calorie" in name):
            found["calories"] = float(amount)
        elif "protein" in name:
            found["protein"] = float(amount)
        elif "carbohydrate" in name:
            found["carbs"] = float(amount)
        elif "fiber" in name:
            found["fiber"] = float(amount)
        elif "fat" in name and "saturated" not in name:
            found["fat"] = float(amount)

    return Nutrients(**found)

# Endpoints

@app.get("/health")
def health():
    """Handler for ()."""

    return {"status": "ok"}

@app.get(
    "/search",
    response_model=SearchResponse,
    summary="Search foods by name",
)
def search_foods(
    query: str = Query(..., min_length=1, description="Food name to search"),
    page: int = Query(1, ge=1, description="Page number (1-based)"),
):
    """
    Calls USDA FoodData Central search with page size fixed at 20.
    Returns simplified results (fdcId, description) plus pagination metadata.
    """
    _ensure_api_key()

    params = {
        "api_key": API_KEY,
        "query": query,
        "pageSize": 20,
        "pageNumber": page,
    }

    try:
        resp = requests.get(SEARCH_URL, params=params, timeout=12)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Upstream request failed: {e}")

    if not resp.ok:
        raise HTTPException(status_code=resp.status_code, detail="USDA search failed")

    data = resp.json() or {}
    foods = _simplify_foods(data.get("foods", []))
    total_hits = int(data.get("totalHits", 0) or 0)
    current_page = int(data.get("currentPage", page) or page)
    total_pages = int(data.get("totalPages", 0) or 0)

    return SearchResponse(
        foods=foods,
        totalHits=total_hits,
        pageNumber=current_page,
        totalPages=total_pages,
    )

@app.get(
    "/food/{fdc_id}",
    response_model=FoodDetails,
    summary="Get key nutrients for a specific food",
)
def get_food_details(
    fdc_id: int = Path(..., ge=1, description="FoodData Central ID"),
):
    """
    Fetches a food by FDC ID and extracts key nutrients:
    calories (kcal), protein/carbs/fat/fiber (g).
    """
    _ensure_api_key()

    url = DETAIL_URL_TMPL.format(fdc_id=fdc_id)
    params = {"api_key": API_KEY}

    try:
        resp = requests.get(url, params=params, timeout=12)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Upstream request failed: {e}")

    if resp.status_code == 404:
        raise HTTPException(status_code=404, detail="Food not found")
    if not resp.ok:
        raise HTTPException(status_code=resp.status_code, detail="USDA detail failed")

    data = resp.json() or {}
    description = data.get("description") or "Unknown item"
    nutrients = _extract_key_nutrients(data)

    return FoodDetails(
        fdcId=int(data.get("fdcId", fdc_id) or fdc_id),
        description=str(description),
        nutrients=nutrients,
    )
