import asyncio
import hmac

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.core.body_limit import BodySizeLimit
from app.core.config import get_settings
from app.emotion.service import EmotionService
from app.llm.provider import ProviderError, make_provider
from app.rag.service import RAGService
from app.schemas.contracts import (
    CaregiverRequest,
    CaregiverResponse,
    CompanionRequest,
    CompanionResponse,
    ContextRequest,
    EmotionRequest,
    EmotionResponse,
    IngestRequest,
    RagRequest,
    RagResponse,
    RecommendationRequest,
    RecommendationResponse,
    SummaryRequest,
    SummaryResponse,
    TrendResponse,
)
from app.services.engine import AIEngine

settings = get_settings()
provider = make_provider(settings)
engine = AIEngine(provider, settings)
emotion = EmotionService(provider, settings)
rag = RAGService(provider, settings)
app = FastAPI(
    title="Hopely Internal AI", version="0.1.0", docs_url=None, redoc_url=None, openapi_url=None
)


async def authenticate(x_internal_service_key: str = Header(default="")):
    if not hmac.compare_digest(x_internal_service_key, settings.internal_service_key):
        raise HTTPException(401, "Unauthorized")


app.add_middleware(BodySizeLimit)


@app.exception_handler(RequestValidationError)
async def validation_error(request, exc):
    return JSONResponse(
        {
            "success": False,
            "error": {
                "code": "validation_error",
                "fields": [{"loc": list(e["loc"]), "type": e["type"]} for e in exc.errors()],
            },
        },
        status_code=422,
    )


@app.exception_handler(HTTPException)
async def http_error(request, exc):
    return JSONResponse(
        {
            "success": False,
            "error": {"code": "unauthorized" if exc.status_code == 401 else "request_failed"},
        },
        status_code=exc.status_code,
    )


@app.exception_handler(PermissionError)
async def permission_error(request, exc):
    return JSONResponse({"success": False, "error": {"code": "consent_required"}}, status_code=403)


@app.exception_handler(ProviderError)
async def provider_error(request, exc):
    return JSONResponse({"success": False, "error": {"code": "ai_unavailable"}}, status_code=503)


@app.exception_handler(Exception)
async def unavailable(request, exc):
    return JSONResponse(
        {"success": False, "error": {"code": "service_unavailable"}}, status_code=503
    )


@app.get("/health")
async def health():
    return {"status": "ok", "service": "hopely-ai"}


protect = [Depends(authenticate)]


@app.post("/v1/ai/companion", response_model=CompanionResponse, dependencies=protect)
async def companion(req: CompanionRequest):
    return await engine.companion(req)


@app.post("/v1/ai/emotion/analyze", response_model=EmotionResponse, dependencies=protect)
async def analyze_emotion(req: EmotionRequest):
    return await emotion.analyze(req.text)


@app.post("/v1/ai/trend/analyze", response_model=TrendResponse, dependencies=protect)
async def trend(req: ContextRequest):
    return engine.trends.analyze(req.context)


@app.post("/v1/ai/recommendations", response_model=RecommendationResponse, dependencies=protect)
async def recommendations(req: RecommendationRequest):
    return await engine.recommendations(req)


@app.post("/v1/ai/doctor-summary", response_model=SummaryResponse, dependencies=protect)
async def summary(req: SummaryRequest):
    return await engine.summary(req)


@app.post("/v1/ai/caregiver-coach", response_model=CaregiverResponse, dependencies=protect)
async def caregiver(req: CaregiverRequest):
    return await engine.caregiver(req)


@app.post("/v1/rag/query", response_model=RagResponse, dependencies=protect)
async def query(req: RagRequest):
    return await rag.query(req)


@app.post("/v1/knowledge/ingest", dependencies=protect)
async def ingest(req: IngestRequest):
    return await asyncio.to_thread(rag.ingest_sync, req)
