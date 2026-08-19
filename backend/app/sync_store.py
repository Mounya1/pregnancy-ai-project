"""Per-user document storage on DynamoDB.

One item per user, holding the whole app state as a JSON blob. That is a
deliberate choice over a table per collection: the client already keeps
everything as one local store, the whole thing is a few hundred kilobytes at
most, and a single item means a sync is one read or one write with no
cross-table consistency to get wrong.

DynamoDB's free tier is 25GB and does not expire, and items are encrypted at
rest by default - which matters here, because this is medical data.
"""

import json
import logging
from datetime import datetime, timezone
from functools import lru_cache

from fastapi import HTTPException

from app.config import settings

logger = logging.getLogger("uvicorn.error")

# DynamoDB caps an item at 400KB. Refusing earlier gives a clear error instead
# of a cryptic ValidationException, and leaves headroom for the envelope.
MAX_DOCUMENT_BYTES = 350_000


@lru_cache(maxsize=1)
def _table():
    if not settings.dynamodb_table:
        raise HTTPException(
            status_code=501,
            detail="This server has no sync table configured.",
        )

    # Imported here, not at module load. Sync is optional, and an optional
    # feature's dependency must not be able to take the whole API down at
    # import time - chat and meal plans do not need boto3 to work.
    try:
        import boto3  # noqa: PLC0415
    except ImportError:
        raise HTTPException(
            status_code=501,
            detail="This server was built without the sync dependencies.",
        )

    session = boto3.session.Session(
        aws_access_key_id=settings.aws_access_key_id or None,
        aws_secret_access_key=settings.aws_secret_access_key or None,
        region_name=settings.aws_region or settings.cognito_region or None,
    )
    return session.resource("dynamodb").Table(settings.dynamodb_table)


def load(user_id: str) -> dict | None:
    """The stored document, or None if this user has never synced."""
    try:
        response = _table().get_item(Key={"user_id": user_id})
    except HTTPException:
        raise
    except Exception:
        logger.exception("sync load failed")
        raise HTTPException(status_code=503, detail="Could not read your saved data.")

    item = response.get("Item")
    if not item:
        return None
    return {
        "updated_at": item.get("updated_at"),
        "data": json.loads(item.get("document", "{}")),
    }


def save(user_id: str, data: dict) -> str:
    """Writes the document. Returns the timestamp it was stored under."""
    document = json.dumps(data, separators=(",", ":"))
    if len(document.encode()) > MAX_DOCUMENT_BYTES:
        raise HTTPException(
            status_code=413,
            detail="Your data is too large to sync. Clearing old history in "
            "Settings will bring it back under the limit.",
        )

    updated_at = datetime.now(timezone.utc).isoformat()
    try:
        _table().put_item(
            Item={
                "user_id": user_id,
                "document": document,
                "updated_at": updated_at,
            }
        )
    except HTTPException:
        raise
    except Exception:
        logger.exception("sync save failed")
        raise HTTPException(status_code=503, detail="Could not save your data.")

    return updated_at


def delete(user_id: str) -> None:
    try:
        _table().delete_item(Key={"user_id": user_id})
    except HTTPException:
        raise
    except Exception:
        logger.exception("sync delete failed")
        raise HTTPException(status_code=503, detail="Could not delete your data.")
