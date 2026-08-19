"""Verifies AWS Cognito access tokens.

The token is the only thing standing between one user's medical records and
another's, so this does real verification: RS256 signature against the pool's
published keys, plus issuer, expiry and token-use checks. Decoding the payload
without checking the signature would let anyone read anyone's data by editing
a base64 string.
"""

import time
from functools import lru_cache

from fastapi import Depends, HTTPException, Request, status

from app.config import settings


class NotConfigured(RuntimeError):
    """Raised when sync is called on a build with no user pool set."""


@lru_cache(maxsize=1)
def _jwk_client():
    if not settings.cognito_user_pool_id or not settings.cognito_region:
        raise NotConfigured

    # Imported lazily for the same reason boto3 is: sync is optional, and the
    # rest of the API must start and serve without its dependencies present.
    from jwt import PyJWKClient  # noqa: PLC0415

    url = (
        f"https://cognito-idp.{settings.cognito_region}.amazonaws.com/"
        f"{settings.cognito_user_pool_id}/.well-known/jwks.json"
    )
    # Cached because it is fetched over the network and rotates rarely; a
    # per-request fetch would add a round trip to every single call.
    return PyJWKClient(url, cache_keys=True)


def verify_access_token(token: str) -> dict:
    """Returns the token claims, or raises HTTPException(401)."""
    try:
        import jwt  # noqa: PLC0415

        signing_key = _jwk_client().get_signing_key_from_jwt(token)
        claims = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            issuer=(
                f"https://cognito-idp.{settings.cognito_region}.amazonaws.com/"
                f"{settings.cognito_user_pool_id}"
            ),
            # Cognito access tokens carry no `aud`; the client id is in
            # `client_id` instead, checked below.
            options={"verify_aud": False},
        )
    except NotConfigured:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="This server has no user pool configured, so sync is unavailable.",
        )
    except ImportError:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="This server was built without the sync dependencies.",
        )
    except HTTPException:
        raise
    except Exception as exc:
        # PyJWT's errors and the network errors from fetching the key set are
        # both possible here, and both mean the same thing to the caller: this
        # session could not be proven valid.
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Your session could not be verified ({type(exc).__name__}). Sign in again.",
        )

    # An id token and an access token are both signed by the same pool, so the
    # signature alone does not prove which one arrived. Only the access token
    # is meant to authorise an API call.
    if claims.get("token_use") != "access":
        raise HTTPException(status_code=401, detail="Wrong token type.")

    if settings.cognito_client_id and claims.get("client_id") != settings.cognito_client_id:
        raise HTTPException(status_code=401, detail="This token is for a different app.")

    if claims.get("exp", 0) < time.time():
        raise HTTPException(status_code=401, detail="Your session has expired. Sign in again.")

    return claims


def current_user_id(request: Request) -> str:
    """FastAPI dependency: the Cognito `sub` of the caller.

    `sub` rather than email, because an email can be changed and would then
    orphan the data it was keyed on.
    """
    header = request.headers.get("Authorization", "")
    if not header.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Sign in to use sync.")
    return verify_access_token(header[7:])["sub"]


UserId = Depends(current_user_id)
