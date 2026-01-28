"""Item API Tests"""

import pytest


@pytest.mark.asyncio
async def test_create_item(client):
    """Test creating an item"""
    response = await client.post(
        "/api/v1/items",
        json={"name": "Test Item", "description": "A test item"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test Item"
    assert data["description"] == "A test item"
    assert "id" in data


@pytest.mark.asyncio
async def test_list_items(client):
    """Test listing items"""
    # Create an item first
    await client.post("/api/v1/items", json={"name": "Item 1"})
    await client.post("/api/v1/items", json={"name": "Item 2"})

    response = await client.get("/api/v1/items")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 2


@pytest.mark.asyncio
async def test_get_item(client):
    """Test getting a single item"""
    # Create an item
    create_response = await client.post(
        "/api/v1/items",
        json={"name": "Get Test"},
    )
    item_id = create_response.json()["id"]

    # Get the item
    response = await client.get(f"/api/v1/items/{item_id}")
    assert response.status_code == 200
    assert response.json()["name"] == "Get Test"


@pytest.mark.asyncio
async def test_get_item_not_found(client):
    """Test getting non-existent item"""
    response = await client.get("/api/v1/items/99999")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_update_item(client):
    """Test updating an item"""
    # Create an item
    create_response = await client.post(
        "/api/v1/items",
        json={"name": "Original Name"},
    )
    item_id = create_response.json()["id"]

    # Update the item
    response = await client.patch(
        f"/api/v1/items/{item_id}",
        json={"name": "Updated Name"},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Updated Name"


@pytest.mark.asyncio
async def test_delete_item(client):
    """Test deleting an item"""
    # Create an item
    create_response = await client.post(
        "/api/v1/items",
        json={"name": "Delete Test"},
    )
    item_id = create_response.json()["id"]

    # Delete the item
    response = await client.delete(f"/api/v1/items/{item_id}")
    assert response.status_code == 204

    # Verify it's deleted
    get_response = await client.get(f"/api/v1/items/{item_id}")
    assert get_response.status_code == 404
