"""
Example items router — replace with your own endpoints.

Demonstrates FastAPI patterns: path params, request body, response models,
and HTTPException. Uses an in-memory store for simplicity.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/items", tags=["Items"])


# --- Schemas ---

class ItemCreate(BaseModel):
    name: str
    description: str = ""


class Item(BaseModel):
    id: int
    name: str
    description: str


# --- In-memory store (replace with DB) ---

_items: dict[int, Item] = {}
_next_id: int = 1


# --- Endpoints ---

@router.get("", response_model=list[Item])
async def list_items():
    """List all items."""
    return list(_items.values())


@router.get("/{item_id}", response_model=Item)
async def get_item(item_id: int):
    """Get a single item by ID."""
    if item_id not in _items:
        raise HTTPException(status_code=404, detail="Item not found")
    return _items[item_id]


@router.post("", response_model=Item, status_code=201)
async def create_item(payload: ItemCreate):
    """Create a new item."""
    global _next_id
    item = Item(id=_next_id, **payload.model_dump())
    _items[_next_id] = item
    _next_id += 1
    return item
