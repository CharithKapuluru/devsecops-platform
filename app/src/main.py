"""FastAPI Application Entry Point"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.routes import router
from core.config import settings
from db.database import init_db
from middleware.security import SecurityHeadersMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    # Startup
    await init_db()
    yield
    # Shutdown
    pass


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="DevSecOps Platform API",
    lifespan=lifespan,
)

# Middleware
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(router)


@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "DevSecOps Platform API", "version": settings.VERSION}


@app.get("/health")
async def health_check():
    """Health check endpoint for ALB"""
    return {"status": "healthy"}


@app.get("/health/ready")
async def readiness_check():
    """Readiness check including database connectivity"""
    from db.database import check_db_connection

    db_healthy = await check_db_connection()
    return {
        "status": "ready" if db_healthy else "not_ready",
        "database": "connected" if db_healthy else "disconnected",
    }
