"""
FastAPI application for {{ cookiecutter.project_name }}.

Runs alongside Django to handle use cases better suited to async Python
(WebSockets, real-time APIs, long-running connections, etc.).
"""

import logging
import sys
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .routers import items_router

settings = get_settings()

logging.basicConfig(
    level=getattr(logging, settings.log_level.upper()),
    format=settings.log_format,
    datefmt=settings.log_date_format,
    handlers=[logging.StreamHandler(sys.stdout)],
)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager for startup/shutdown events."""
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")
    logger.info(f"Environment: {settings.environment}")
    yield
    logger.info("Application shutdown complete")


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description="{{ cookiecutter.description }}",
        lifespan=lifespan,
        debug=settings.debug,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=settings.cors_allow_credentials,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    register_routes(app)
    return app


def register_routes(app: FastAPI) -> None:
    """Register all routes with the FastAPI application."""

    @app.get("/health", tags=["Health"])
    async def health_check() -> dict[str, Any]:
        """Basic health check for container orchestration."""
        return {
            "status": "healthy",
            "version": settings.app_version,
            "environment": settings.environment,
        }

    @app.get("/health/ready", tags=["Health"])
    async def readiness_check() -> dict[str, Any]:
        """Readiness check — extend with DB/Redis checks as needed."""
        return {
            "status": "ready",
        }

    app.include_router(items_router)


app = create_app()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "fastapi_server.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower(),
    )
