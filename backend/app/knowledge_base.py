"""
Builds and loads a FAISS vector store over the medical knowledge base.

Run `python -m app.knowledge_base` to build the index from
seed_data/medical_knowledge.json. In production, swap this JSON seed
for a real ingestion pipeline pulling structured guidance from
ACOG / CDC / FDA / NIH / USDA (scraped + reviewed, not scraped + trusted blindly).

The built index ships inside the image so the first request does not pay to
build it. It is regenerated automatically when the seed no longer matches the
index it was built from - see _seed_digest.
"""
import hashlib
import json
import os
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings
from langchain.docstore.document import Document

from app.config import settings

SEED_PATH = os.path.join(os.path.dirname(__file__), "..", "seed_data", "medical_knowledge.json")

# Written beside the index at build time and compared on load.
_STAMP_NAME = "seed.sha256"

# One store per process. Rebuilding OpenAIEmbeddings and re-reading the index
# from disk on every question was pure overhead - the index is read-only and
# a few hundred KB.
_cache: FAISS | None = None


def _seed_digest() -> str:
    with open(SEED_PATH, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def _stamp_path() -> str:
    return os.path.join(settings.vector_store_path, _STAMP_NAME)


def _stamp_matches() -> bool:
    """Whether the index on disk was built from the seed file we have now.

    Without this, editing the knowledge base and forgetting to rebuild leaves
    the app answering from the old index with no visible error - every new
    topic simply comes back as "Unknown - Ask Your Doctor", which looks like a
    model problem rather than a stale artifact.
    """
    try:
        with open(_stamp_path()) as f:
            return f.read().strip() == _seed_digest()
    except OSError:
        # No stamp: an index built before stamping existed. Treat it as stale
        # once; the rebuild writes a stamp and it stops being a question.
        return False


def _embeddings() -> OpenAIEmbeddings:
    return OpenAIEmbeddings(model=settings.embedding_model, api_key=settings.openai_api_key)


def build_vector_store():
    with open(SEED_PATH) as f:
        entries = json.load(f)

    docs = [
        Document(
            page_content=f"{e['topic']}: {e['content']}",
            metadata={"source": e["source"], "topic": e["topic"]},
        )
        for e in entries
    ]

    store = FAISS.from_documents(docs, _embeddings())
    store.save_local(settings.vector_store_path)
    with open(_stamp_path(), "w") as f:
        f.write(_seed_digest())
    print(f"Vector store built with {len(docs)} documents at {settings.vector_store_path}")
    return store


def load_vector_store():
    global _cache
    if _cache is not None:
        return _cache

    if not os.path.exists(settings.vector_store_path) or not _stamp_matches():
        _cache = build_vector_store()
    else:
        _cache = FAISS.load_local(
            settings.vector_store_path, _embeddings(), allow_dangerous_deserialization=True
        )
    return _cache


def retrieve(query: str, k: int = 3):
    store = load_vector_store()
    return store.similarity_search(query, k=k)


if __name__ == "__main__":
    build_vector_store()
