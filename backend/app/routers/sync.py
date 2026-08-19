from fastapi import APIRouter, Depends

from app import sync_store
from app.auth_jwt import current_user_id
from app.schemas import SyncPullResponse, SyncPushRequest, SyncPushResponse

router = APIRouter(prefix="/sync", tags=["sync"])


@router.get("", response_model=SyncPullResponse)
def pull(user_id: str = Depends(current_user_id)):
    """Everything stored for the signed-in user.

    A first sync from a new device returns `data: null` rather than an empty
    object, so the client can tell "nothing saved yet" apart from "saved, and
    it was empty" - the difference between keeping local data and wiping it.
    """
    stored = sync_store.load(user_id)
    if stored is None:
        return SyncPullResponse(data=None, updated_at=None)
    return SyncPullResponse(data=stored["data"], updated_at=stored["updated_at"])


@router.put("", response_model=SyncPushResponse)
def push(req: SyncPushRequest, user_id: str = Depends(current_user_id)):
    updated_at = sync_store.save(user_id, req.data)
    return SyncPushResponse(updated_at=updated_at)


@router.delete("", status_code=204)
def wipe(user_id: str = Depends(current_user_id)):
    """Deletes the server copy. The device keeps its own."""
    sync_store.delete(user_id)
