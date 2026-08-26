# Changelog IoTDeviceManagement

<!-- TOC:START -->
## Table of Contents
- [r1.2](#r12)
- [r1.1](#r11)
<!-- TOC:END -->

**Please be aware that the project will have frequent updates to the main branch. There are no compatibility guarantees associated with code in any branch, including main, until it has been released. For example, changes may be reverted before a release is published. For the best results, use the latest published release.**

The below sections record the changes for each API version in each release as follows:

* for an alpha release, the delta with respect to the previous release
* for the first release-candidate, all changes since the last public release
* for subsequent release-candidate(s), only the delta to the previous release-candidate
* for a public release, the consolidated changes since the previous public release

# r1.2

## Release Notes

This release candidate contains the definition and documentation of
* esim-profile-management 0.1.0-rc.1

The API definition(s) are based on
* Commonalities r4.3 (0.8.0)
* Identity and Consent Management r4.2 (0.5.0)

## esim-profile-management 0.1.0-rc.1

**esim-profile-management 0.1.0-rc.1 is the first release-candidate version of this API.**

- API definition **with inline documentation**:
  - [View it on ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/camaraproject/IoTDeviceManagement/r1.2/code/API_definitions/esim-profile-management.yaml&nocors)
  - [View it on Swagger Editor](https://camaraproject.github.io/swagger-ui/?url=https://raw.githubusercontent.com/camaraproject/IoTDeviceManagement/r1.2/code/API_definitions/esim-profile-management.yaml)
  - OpenAPI [YAML spec file](https://github.com/camaraproject/IoTDeviceManagement/blob/r1.2/code/API_definitions/esim-profile-management.yaml)

As the first release-candidate with no preceding public release, this entry records all changes since the initial (alpha) content. There is no previous release-candidate to compare against.

### Breaking changes

* N/A

### Added

* New `409` (conflict) error response on the relevant operations.
* `Location` header on operation-creating (`202`) responses.
* Optional `EID` on the enable, disable, delete, and set-fallback operations to identify the target eUICC directly (in addition to the required `ICCID`); when both are supplied the `EID`/`ICCID` pairing is asserted. Added a corresponding set-fallback request example.
* Status retrieval now also accepts `EID` and `ICCID` together (specific profile, pairing asserted), in addition to either identifier alone.
* Basic test cases (`code/Test_definitions/esim-profile-management.feature`).
* User-story documentation for the eSIM Profile Management API.

### Changed

* Operation `status` enum is now `[ACCEPTED, COMPLETED]` (uppercase); operation failure is reported via `result.outcome` (`FAILED`) on a `COMPLETED` operation rather than a `failed` status.
* eSIM-specific `422` error codes are now `[SERVICE_NOT_APPLICABLE, ESIM_PROFILE_MANAGEMENT.IDENTIFIER_MISMATCH]`, replacing the earlier `MISSING_IDENTIFIER`, `UNSUPPORTED_IDENTIFIER`, and `UNNECESSARY_IDENTIFIER` codes with the API-specific `ESIM_PROFILE_MANAGEMENT.IDENTIFIER_MISMATCH` (EID and ICCID each valid but not matching the same eUICC).
* The `/download` request now accepts only the `EID`; the request body rejects the `ICCID` and any other undeclared properties. The `ICCID` is assigned during download and returned in the response.
* Broadened error-response coverage: `404` and `422` responses now declared on more operations.
* A `COMPLETED` operation is retrievable only for a provider-defined period, after which `GET /operations/{operationId}` returns `404`.
* Reworked and streamlined the API General Description documentation (operation model, operation-state behaviour, device-reachability requirements, and pre-requisites) for clarity and alignment with the current operation model.

### Fixed

* N/A

### Removed

* N/A

**Full Changelog**: https://github.com/camaraproject/IoTDeviceManagement/commits/r1.2

# r1.1

## Release Notes

This pre-release contains the definition and documentation of
* esim-profile-management 0.1.0-alpha.1

The API definition(s) are based on
* Commonalities 0.8.0
* Identity and Consent Management 0.5.0

## esim-profile-management 0.1.0-alpha.1

**esim-profile-management 0.1.0-alpha.1 is the first alpha version of this API.**

- API definition **with inline documentation**:
  - [View it on ReDoc](https://redocly.github.io/redoc/?url=https://raw.githubusercontent.com/camaraproject/IoTDeviceManagement/r1.1/code/API_definitions/esim-profile-management.yaml&nocors)
  - [View it on Swagger Editor](https://camaraproject.github.io/swagger-ui/?url=https://raw.githubusercontent.com/camaraproject/IoTDeviceManagement/r1.1/code/API_definitions/esim-profile-management.yaml)
  - OpenAPI [YAML spec file](https://github.com/camaraproject/IoTDeviceManagement/blob/r1.1/code/API_definitions/esim-profile-management.yaml)

### Added

* Initial alpha release of the eSIM Profile Management API (`esim-profile-management 0.1.0-alpha.1`), providing eSIM Profile lifecycle management on the device eUICC — with download, enable, disable, delete, set-fallback, status retrieval, and operation-tracking endpoints.

### Changed

* N/A

### Fixed

* N/A

### Removed

* N/A

**Full Changelog**: https://github.com/camaraproject/IoTDeviceManagement/commits/r1.1

