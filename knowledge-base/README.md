# Curated knowledge
No medical article is preloaded or falsely marked as clinically reviewed.

An ADMIN can POST /api/admin/knowledge/ingest with text and source metadata. For PDF/TXT/MD use the internal CLI after a real reviewer approves the source:

```sh
docker compose exec ai-service python ingest.py /documents/approved.pdf --metadata /documents/approved.metadata.json --url http://localhost:8001
```

Mount only the reviewed document folder to /documents. Metadata fields: source_id, title, publisher, source_url (optional), published_at (optional), document_version, reviewed_by, reviewed=true. Do not place patient records here. Use the source publisher's permission/license. A different embedding model requires re-indexing all sources, even if vector dimensions match.

In mock mode the knowledge screen explicitly abstains; it does not pretend an empty database has medical answers.
