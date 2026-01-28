"""Database Configuration and Session Management"""

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import NullPool

from core.config import settings

# Create async engine
database_url = settings.get_database_url()
engine = create_async_engine(
    database_url,
    echo=settings.DEBUG,
    poolclass=NullPool,  # Use NullPool for serverless/container environments
) if database_url else None

# Session factory
async_session = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# Base class for models
Base = declarative_base()


async def get_db() -> AsyncSession:
    """Dependency to get database session"""
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """Initialize database tables"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def check_db_connection() -> bool:
    """Check database connectivity"""
    try:
        async with async_session() as session:
            await session.execute("SELECT 1")
            return True
    except Exception:
        return False
