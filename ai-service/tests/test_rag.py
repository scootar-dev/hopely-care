import asyncio

import pytest
from qdrant_client import QdrantClient

from app.core.config import Settings
from app.llm.provider import MockProvider, ProviderError
from app.rag.service import COLLECTION, RAGService
from app.schemas.contracts import IngestRequest, RagRequest, RagResult


class Embedder:
    def encode(self, texts):
        return [[1.0, 0.0, 0.0] for _ in texts]


class CitedProvider(MockProvider):
    async def structured(self, task, payload, schema):
        if task == "rag":
            return RagResult(
                answer="Informasi dari dokumen yang disetujui.",
                citation_ids=[payload["evidence"][0]["citation_id"]],
                confidence=0.8,
            )
        return await super().structured(task, payload, schema)


def make_service(provider=None):
    settings = Settings(
        internal_service_key="x" * 32,
        mock_ai_mode=False,
        llm_api_key="test-only-not-real",
        llm_model="test",
    )
    return RAGService(
        provider or CitedProvider(), settings, client=QdrantClient(":memory:"), embedder=Embedder()
    )


def request(text):
    return IngestRequest(
        source_id="curated",
        title="Reviewed test",
        publisher="Test publisher",
        document_version="1",
        reviewed_by="Test reviewer",
        reviewed=True,
        text=text,
    )


def test_ingestion_replaces_old_chunks():
    service = make_service()
    service.ingest_sync(request("Approved educational reference. " * 100))
    before = service.client.count(COLLECTION).count
    service.ingest_sync(request("Approved short educational reference document."))
    assert before > 1
    assert service.client.count(COLLECTION).count == 1


def test_sources_come_from_retrieved_metadata():
    service = make_service()
    service.ingest_sync(request("Approved educational reference document."))
    result = asyncio.run(service.query(RagRequest(question="reference")))
    assert result.sources[0]["publisher"] == "Test publisher"
    assert result.sources[0]["source_id"] == "curated"


def test_invented_citation_is_blocked():
    class Bad(CitedProvider):
        async def structured(self, task, payload, schema):
            if task == "rag":
                return RagResult(answer="x", citation_ids=["invented"], confidence=0.9)
            return await super().structured(task, payload, schema)

    service = make_service(Bad())
    service.ingest_sync(request("Approved educational reference document."))
    with pytest.raises(ProviderError):
        asyncio.run(service.query(RagRequest(question="reference")))


def test_empty_collection_abstains():
    service = make_service()
    result = asyncio.run(service.query(RagRequest(question="reference")))
    assert result.confidence == 0
    assert result.sources == []
