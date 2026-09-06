# eSIM Profile Management API — Error Handling Guide

A practical guide for implementers: which HTTP status and error `code` to return in each situation.
For schemas see the OpenAPI spec; for the operation lifecycle see the General Description.

**Golden rule.**

Validation, authorization, and state problems are rejected **synchronously** with a `4xx` and no `operationId`.
Device-side runtime failures (unreachable device, OTA timeout, SM-DP+ error) are **accepted** with `202` and reported later on the operation as `result.outcome = FAILED`.

## When to return each code

| Situation | Status | `code` |
|---|---|---|
| Request body malformed, a required property missing, an unknown property present, or invalid parameters are supplied | `400` | `INVALID_ARGUMENT` |
| Missing, invalid, or expired access token | `401` | `UNAUTHENTICATED` |
| Token valid but lacks the required scope | `403` | `PERMISSION_DENIED` |
| An EID or ICCID does not match any known device or eSIM Profile | `404` | `IDENTIFIER_NOT_FOUND` |
| The `operationId` is unknown, or its operation has been purged after retention | `404` | `NOT_FOUND` |
| The eSIM Profile exists but its current state does not allow the operation (e.g. deleting a profile that is not DISABLED) | `409` | `INCOMPATIBLE_STATE` |
| Another operation is already in progress on the same eSIM Profile or device | `409` | `ABORTED` |
| The operation cannot apply to this profile/device by its nature (e.g. profile not eligible as a fallback, or not provisioned with a connectivity service that can be enabled) | `422` | `SERVICE_NOT_APPLICABLE` |
| A supplied EID and ICCID are each valid, but the ICCID is not installed on that EID | `422` | `ESIM_PROFILE_MANAGEMENT.IDENTIFIER_MISMATCH` |
| Rate or spike limit reached | `429` | `TOO_MANY_REQUESTS` |
| Business quota exhausted | `429` | `QUOTA_EXCEEDED` |

Request-body strictness: any property not declared in the specification is rejected with a `400 INVALID_ARGUMENT`, at any nesting level.

`INCOMPATIBLE_STATE` is for a state that could later change;

`SERVICE_NOT_APPLICABLE` is for an operation that cannot apply to that profile/device regardless of state.

## Codes allowed per operation

| Operation | Allowed error codes (beyond 400/401/403/429) |
|---|---|
| `/download` | `IDENTIFIER_NOT_FOUND` |
| `/enable` `/disable` `/delete` `/set-fallback` | `IDENTIFIER_NOT_FOUND`, `INCOMPATIBLE_STATE`, `ABORTED`, `SERVICE_NOT_APPLICABLE`, `IDENTIFIER_MISMATCH` |
| `/retrieve-status` | `IDENTIFIER_NOT_FOUND`, `IDENTIFIER_MISMATCH` |
| `/operations/{operationId}` | `NOT_FOUND` |

## Error body shape

All errors carry `status`, `code`, `message`, and echo the `x-correlator` header.

```json
{
  "status": 409,
  "code": "INCOMPATIBLE_STATE",
  "message": "The eSIM Profile is not in a state compatible with the requested operation."
}
```
