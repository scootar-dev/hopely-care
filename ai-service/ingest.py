"""Curated PDF/TXT/Markdown ingestion. Metadata is explicit, never inferred as reviewed."""

import argparse
import json
from pathlib import Path

import httpx
from pypdf import PdfReader

from app.core.config import get_settings
from app.schemas.contracts import IngestRequest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("document", type=Path)
    parser.add_argument(
        "--metadata",
        type=Path,
        required=True,
        help="JSON with source_id, title, publisher, version, reviewer, reviewed=true",
    )
    parser.add_argument("--url", default="http://localhost:8001")
    args = parser.parse_args()
    if args.document.stat().st_size > 20 * 1024 * 1024:
        parser.error("Document exceeds 20 MiB")
    suffix = args.document.suffix.lower()
    if suffix == ".pdf":
        text = "\n".join(p.extract_text() or "" for p in PdfReader(args.document).pages)
    elif suffix in [".txt", ".md"]:
        text = args.document.read_text(encoding="utf-8")
    else:
        parser.error("Supported: PDF, TXT, MD")
    request = IngestRequest.model_validate({**json.loads(args.metadata.read_text()), "text": text})
    response = httpx.post(
        args.url + "/v1/knowledge/ingest",
        json=request.model_dump(mode="json"),
        headers={"X-Internal-Service-Key": get_settings().internal_service_key},
        timeout=180,
    )
    response.raise_for_status()
    print(json.dumps(response.json(), ensure_ascii=False))


if __name__ == "__main__":
    main()
