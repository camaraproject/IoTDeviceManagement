# High level description of eSIM Profile Management concept and API

## Introduction

eSIM (embedded SIM) technology allows remote provisioning and management of cellular connectivity without physical SIM card replacement. The CAMARA eSIM Profile Management API provides a unified interface for eSIM Profile lifecycle operations including download, enable, disable, delete, and fallback configuration.

The target of the eSIM Profile operations is typically the eUICC on the device (as opposed to the cellular network).

**Terminology Note**: In this API, "eSIM Profile" refers to downloadable connectivity configurations installed on eSIM hardware (eUICC). "eSIM" refers to the hardware itself.

**Key roles**

| **Role Name** | **Description** |
| ---- | ------- |
| API Consumer | The entity that consumes the eSIM Profile Management APIs |
| API Provider | The entity that provides the eSIM Profile Management APIs |
| Network Provider | The entity that provides the physical network resources and Remote SIM Provisioning (RSP) platform |
| Device Owner | The entity that owns or manages the devices containing eSIM hardware |

## eSIM Profile Management Operations

The API operations are summarized in the table below:

| **Operation** | **Purpose of the Operation** | **Key Abstractions and concepts** |
| ---- | ------- | ----|
| Download eSIM Profile | Download and install new eSIM Profile to device | An eSIM Profile represents a downloadable connectivity configuration that can be installed on eSIM hardware (eUICC). The download operation combines SGP.32 Profile Download and Installation into a single operation resulting in a DISABLED eSIM Profile ready for enabling. The ICCID is assigned during download and returned in the response. |
| Enable eSIM Profile | Enable an eSIM Profile which is already downloaded on the device | eSIM Profile Enabling makes an installed eSIM Profile active for cellular connectivity (assuming valid connectivity services are configured in the eSIM Profile). Only one eSIM Profile can be enabled per device - enabling an eSIM Profile automatically disables any currently active eSIM Profile. |
| Disable eSIM Profile | Disable active eSIM Profile | eSIM Profile Disabling makes an active eSIM Profile inactive, removing cellular connectivity until another eSIM Profile is enabled. The eSIM Profile remains installed and can be re-enabled. |
| Delete eSIM Profile | Permanently remove eSIM Profile from device | eSIM Profile Deletion permanently removes an eSIM Profile from the device. This operation is irreversible and the eSIM Profile cannot be recovered. The eSIM Profile must be in DISABLED state before deletion. |
| Set Fallback eSIM Profile | Configure backup eSIM Profile | Fallback Configuration designates a backup eSIM Profile that can be automatically activated if the primary eSIM Profile fails or becomes unavailable, ensuring service continuity. |
| Retrieve Status | Query current status of eSIM Profiles on device | eSIM Profile Status provides current state information for all eSIM Profiles on a device, including ENABLED, DISABLED, and fallback eSIM Profile identification. |

All operations that require device interaction (download, enable, disable, delete, set-fallback) are asynchronous, returning a `202 Accepted` with an `operationId` for tracking. Retrieve-status is synchronous and returns `200 OK`.

The status and results of an asynchronous operation are retrieved by polling the GET `/operations/{operationId}` endpoint. Event-based notifications are not supported in this version.

**Figure**: High-level sequence of steps

<img src="./diagrams/high-level-steps.png" alt="High-level sequence of steps" width="180" />

## Pre-requisites

Before using the eSIM Profile Management API, the API Consumer must establish a relationship with an API Provider. In particular:

- The API Consumer is responsible for choosing and contacting an API Provider that fulfils their requirements.
- Agreements must be in place between the API Consumer and API Provider covering service plans and connectivity options, geographic coverage areas, device compatibility requirements, and terms and conditions including pricing.
- The `activationCode` used in the `/download` operation is obtained from the API Provider and is therefore API Provider specific.
- The API Provider is responsible for telling the API Consumer the FQDN of their `esim-profile-management` API.

This preparation phase is **outside the scope** of the eSIM Profile Management API.

**Device connectivity**: All operations act on the device over-the-air (download, enable, disable, delete, set-fallback). The target device must therefore be reachable over cellular or Wi-Fi when an operation runs. Download is the notable case. Because it may deliver the device's first eSIM Profile, that initial connectivity has to come from another bearer, such as an existing profile, a bootstrap profile, or Wi-Fi. The API does not provide this connectivity itself. A device that cannot be reached at all cannot be operated on through it. If the device becomes unreachable mid-operation, the operation completes with a `FAILED` outcome rather than being rejected synchronously.

eSIM Profile Management APIs currently do not support procurement of eSIM Profiles and such a capability may be added in future revisions.

## High-level flow

<img src="./diagrams/high-level-flow.png" alt="High-level flow" width="750" />

Main steps:

1. **Download eSIM Profile**: Downloads eSIM Profile to device (EID + activationCode required; ICCID assigned during download)
2. **Enable eSIM Profile**: Activates downloaded eSIM Profile for connectivity
3. **Configure Fallback**: Optional backup eSIM Profile for service continuity
4. **Active Connectivity**: Device uses enabled eSIM Profile with optional fallback

## States of eSIM Profiles

eSIM Profiles have two states: DISABLED and ENABLED.

**Figure**: lifecycle of an eSIM Profile

<img src="./diagrams/esim-profile-lifecycle.png" alt="Lifecycle of an eSIM Profile" width="450" />

- DISABLED: eSIM Profile installed but not active
- ENABLED: eSIM Profile active and providing connectivity
- Only one eSIM Profile can be enabled per device
- Deletion permanently removes eSIM Profiles

## States of operations

An asynchronous request has one of two outcomes.
It is either rejected synchronously with a `4xx`, in which case no `operationId` is issued, or it is accepted with a `202`, an `operationId`, and `status: ACCEPTED`.
See the [Error Handling Guide](./eSIM-Profile-Management-ErrorHandling.md) for the error codes and the condition that triggers each.

Once accepted, the operation has two status values: `ACCEPTED` and `COMPLETED`. The `status` reflects the operation lifecycle only, and `COMPLETED` is terminal. The final result is carried in `result.outcome` (`SUCCESS` or `FAILED`). A failure is described by a human-readable `result.failureReason`. Today a `FAILED` outcome is typically a device-side failure, such as the device being unreachable, an OTA timeout, or an SM-DP+ error. Which failures are detected before acceptance (a 4xx) versus after acceptance (on the operation) may evolve in future versions, as may the addition of a machine-readable failure code.

**Figure**: lifecycle of an operation

<img src="./diagrams/operation-lifecycle.png" alt="Lifecycle of an operation" width="275" />

- `ACCEPTED`: Operation queued for processing
- `COMPLETED`: Operation finished (check `result.outcome` for `SUCCESS` or `FAILED`)

The API Consumer must poll `GET /operations/{operationId}` to observe the transition to `COMPLETED`. There is no push or callback notification in this version; callbacks and event notifications may be added in a future version. A `COMPLETED` operation remains retrievable only for a provider-defined period; once purged, the endpoint returns `404`, so consumers must not rely on long-term availability.



## Device and eSIM Profile Identification

**Identifiers:**
- **eid**: eUICC Identifier (identifies eSIM hardware)
- **iccid**: eSIM Profile Identifier (identifies specific eSIM Profile)


**Usage:**
- Enable/disable/delete/set-fallback require ICCID; the EID may also be supplied (see below)
- Download requires EID (device targeting); the ICCID is assigned during download
- Status retrieval accepts the EID (all profiles on the device), the ICCID (a specific profile), or both (see below)

These are the mandatory identifiers per operation. The optional EID is discussed below; note that a specific implementation may additionally require the EID even where only the ICCID is mandated above.

For set-fallback in particular, the ICCID identifies the target eSIM Profile to designate as fallback, while the EID, when supplied, identifies the eUICC on which to set it.

**When and why a consumer supplies both identifiers**

Supplying both the EID and the ICCID together is always optional; providing only the mandatory identifier for an operation is fully supported. The ICCID identifies the target eSIM Profile, so the EID is not normally needed to determine which profile is meant. A consumer that has downloaded a profile already holds both identifiers — the EID it supplied at download and the ICCID returned in the response — so supplying the second identifier is never a means to discover an unknown value. It serves two purposes:

- **Routing.** The API provider may not immediately know which device currently holds a given ICCID, and resolving that mapping can require additional interaction with the device. IoT deployments often avoid such interaction routinely to conserve device data and energy. Supplying the EID lets the provider route the operation to the target device directly, rather than resolving the ICCID first.
- **Defensive assertion.** Supplying both asks the provider to confirm the pairing before acting: if the ICCID is not installed on the identified device, the request is rejected rather than applied to an unintended target.

For status retrieval specifically: supplying only the EID returns all profiles on the device, supplying only the ICCID returns that single profile, and supplying both returns that profile subject to the same pairing assertion.

When both an EID and an ICCID are provided and each is individually valid, but the ICCID does not correspond to an eSIM Profile installed on the eUICC identified by the EID, the request is rejected with `422 ESIM_PROFILE_MANAGEMENT.IDENTIFIER_MISMATCH`.

## Operation Status Retrieval

The status and result of an asynchronous operation are retrieved by polling:
- GET /esim-profile-management/operations/{operationId}

The consumer polls until `status` is `COMPLETED`, then reads `result.outcome`. The operation resource may later return `404` once it has been purged (see States of operations).

Event-based notifications (e.g. CloudEvents callbacks to a sink URL) are not supported in this version and may be added in a future version.

## Security and Authorization

- OIDC authentication with granular scopes
- Device ownership validation
- Standard CAMARA error responses