"""Item Schemas"""

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ItemBase(BaseModel):
    """Base item schema"""

    name: str
    description: str | None = None


class ItemCreate(ItemBase):
    """Schema for creating items"""

    pass


class ItemUpdate(BaseModel):
    """Schema for updating items"""

    name: str | None = None
    description: str | None = None


class ItemResponse(ItemBase):
    """Schema for item responses"""

    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
    updated_at: datetime
