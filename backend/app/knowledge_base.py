"""
Builds and loads a FAISS vector store over the medical knowledge base.

Run `python -m app.knowledge_base` once to build the index from
seed_data/medical_knowledge.json. In production, swap this JSON seed
for a real ingestion pipeline pulling structured guidance from
ACOG / CDC / FDA / NIH / USDA (scraped + reviewed, not scraped + trusted blindly).
"""
import json
import os
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings
from langchain.docstore.document import Document

from app.config import settings

SEED_PATH = os.path.join(os.path.dirname(__file__), "..", "seed_data", "medical_knowledge.json")


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

    embeddings = OpenAIEmbeddings(model=settings.embedding_model, api_key=settings.openai_api_key)
    store = FAISS.from_documents(docs, embeddings)
    store.save_local(settings.vector_store_path)
    print(f"Vector store built with {len(docs)} documents at {settings.vector_store_path}")
    return store


def load_vector_store():
    embeddings = OpenAIEmbeddings(model=settings.embedding_model, api_key=settings.openai_api_key)
    if not os.path.exists(settings.vector_store_path):
        return build_vector_store()
    return FAISS.load_local(
        settings.vector_store_path, embeddings, allow_dangerous_deserialization=True
    )


def retrieve(query: str, k: int = 3):
    store = load_vector_store()
    return store.similarity_search(query, k=k)


if __name__ == "__main__":
    build_vector_store()
