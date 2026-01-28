"""Item Model"""

from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, String, Text

from db.database import Base


class Item(Base):
    """Sample item model"""

    __tablename__ = "items"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<Item(id={self.id}, name={self.name})>"
