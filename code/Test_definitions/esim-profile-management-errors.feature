Feature: CAMARA eSIM Profile Management API, vwip - Error and semantic scenarios
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  #
  # Testing assets:
  # * A valid EID for a device with an eUICC
  # * A valid ICCID for an existing eSIM Profile in ENABLED state
  # * A valid EID and a valid ICCID that are each individually schema-compliant, but where
  #   the ICCID is NOT installed on the eUICC identified by that EID (unpaired combination)
  # * An EID and an ICCID that are schema-compliant but do not identify any existing device/profile
  # * The means to submit an operation whose target device is unreachable, so that it
  #   completes with a FAILED outcome, and the operationId of such an operation
  # * A valid ICCID for an existing eSIM Profile that is not eligible to serve as a
  #   fallback (so that set-fallback is not applicable to it)
  #
  # Note: Unless a scenario states otherwise, request bodies are assumed to be otherwise
  # valid, with only the property under test deviating.
  #
  # References to OAS spec schemas refer to schemas specified in esim-profile-management.yaml

  Background: Common eSIM Profile Management setup
    Given an environment at "apiRoot"
    And the header "Authorization" is set to a valid access token
    And the header "Content-Type" is set to "application/json"
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"

  # -------------------------------------------------------------------------
  # 400 - Schema / request body validation
  # -------------------------------------------------------------------------

  @esim_profile_errors_400_01_identifier_not_schema_compliant
  Scenario Outline: <operationId> is rejected when an identifier does not comply with the schema
    Given the resource "/esim-profile-management/vwip/<endpoint>"
    And the request body property "<property>" does not comply with the OAS schema at "<schema>"
    When the request "<operationId>" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | endpoint       | operationId            | property             | schema                               |
      | download       | downloadEsimProfile    | $.esimProfile.eid    | /components/schemas/ESimProfileEid   |
      | enable         | enableEsimProfile      | $.esimProfile.iccid  | /components/schemas/ESimProfileIccid |
      | disable        | disableEsimProfile     | $.esimProfile.iccid  | /components/schemas/ESimProfileIccid |
      | delete         | deleteEsimProfile      | $.esimProfile.iccid  | /components/schemas/ESimProfileIccid |
      | set-fallback   | setFallbackEsimProfile | $.esimProfile.iccid  | /components/schemas/ESimProfileIccid |
      | retrieve-status| getEsimProfileStatus   | $.esimProfile.iccid  | /components/schemas/ESimProfileIccid |
      | retrieve-status| getEsimProfileStatus   | $.esimProfile.eid    | /components/schemas/ESimProfileEid   |

  @esim_profile_errors_400_02_required_property_missing
  Scenario Outline: <operationId> is rejected when a required property is missing
    Given the resource "/esim-profile-management/vwip/<endpoint>"
    And the request body property "<property>" is not included
    When the request "<operationId>" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | endpoint       | operationId            | property             |
      | download       | downloadEsimProfile    | $.esimProfile.eid    |
      | download       | downloadEsimProfile    | $.activationCode     |
      | enable         | enableEsimProfile      | $.esimProfile.iccid  |
      | disable        | disableEsimProfile     | $.esimProfile.iccid  |
      | delete         | deleteEsimProfile      | $.esimProfile.iccid  |
      | set-fallback   | setFallbackEsimProfile | $.esimProfile.iccid  |

  # Request body strictness: undeclared properties are rejected
  # at any nesting level, on any endpoint
  @esim_profile_errors_400_03_unknown_property
  Scenario: A request body with an undeclared property is rejected
    Given the resource "/esim-profile-management/vwip/enable"
    And the request body property "$.esimProfile.iccid" is set to a valid ICCID
    And the request body property "$.esimProfile.unknownProperty" is set to "x"
    When the request "enableEsimProfile" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @esim_profile_errors_400_04_retrieve_status_no_identifier
  Scenario: Retrieve status is rejected when neither EID nor ICCID is provided
    Given the resource "/esim-profile-management/vwip/retrieve-status"
    And the request body property "$.esimProfile" is set to: {}
    When the request "getEsimProfileStatus" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # -------------------------------------------------------------------------
  # 401 / 403 - Authentication and authorization
  # -------------------------------------------------------------------------

  @esim_profile_errors_401_01_no_valid_token
  Scenario Outline: <operationId> is rejected without a valid access token
    Given the resource "/esim-profile-management/vwip/<endpoint>"
    And the header "Authorization" is set to an invalid access token
    When the request "<operationId>" is sent
    Then the response status code is 401
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

    Examples:
      | endpoint       | operationId            |
      | download       | downloadEsimProfile    |
      | enable         | enableEsimProfile      |
      | disable        | disableEsimProfile     |
      | delete         | deleteEsimProfile      |
      | set-fallback   | setFallbackEsimProfile |
      | retrieve-status| getEsimProfileStatus   |

  @esim_profile_errors_403_01_missing_scope
  Scenario Outline: <operationId> is rejected when the access token lacks the required scope
    Given the resource "/esim-profile-management/vwip/<endpoint>"
    And the header "Authorization" is set to a valid access token that lacks the "<scope>" scope
    When the request "<operationId>" is sent
    Then the response status code is 403
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

    Examples:
      | endpoint       | operationId            | scope                                              |
      | download       | downloadEsimProfile    | iot-device-management:esim-profiles:download       |
      | enable         | enableEsimProfile      | iot-device-management:esim-profiles:enable         |
      | disable        | disableEsimProfile     | iot-device-management:esim-profiles:disable        |
      | delete         | deleteEsimProfile      | iot-device-management:esim-profiles:delete         |
      | set-fallback   | setFallbackEsimProfile | iot-device-management:esim-profiles:set-fallback   |
      | retrieve-status| getEsimProfileStatus   | iot-device-management:esim-profiles:retrieve-status|

  # -------------------------------------------------------------------------
  # 404 - Identifier / resource not found
  # -------------------------------------------------------------------------

  @esim_profile_errors_404_01_identifier_not_found
  Scenario Outline: <operationId> is rejected when the identifier does not match any device/profile
    Given the resource "/esim-profile-management/vwip/<endpoint>"
    And the request body property "<property>" is compliant with the schema but does not identify a valid <target>
    When the request "<operationId>" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" contains a user friendly text

    Examples:
      | endpoint       | operationId            | property             | target       |
      | download       | downloadEsimProfile    | $.esimProfile.eid    | device       |
      | enable         | enableEsimProfile      | $.esimProfile.iccid  | eSIM Profile |
      | disable        | disableEsimProfile     | $.esimProfile.iccid  | eSIM Profile |
      | delete         | deleteEsimProfile      | $.esimProfile.iccid  | eSIM Profile |
      | set-fallback   | setFallbackEsimProfile | $.esimProfile.iccid  | eSIM Profile |
      | retrieve-status| getEsimProfileStatus   | $.esimProfile.iccid  | eSIM Profile |

  @esim_profile_errors_404_02_operation_not_found
  Scenario: Retrieve operation is rejected when the operationId is unknown or expired
    Given the resource "/esim-profile-management/vwip/operations/{operationId}"
    And the path parameter "operationId" is compliant with the schema but does not identify a known operation
    When the request "retrieveOperation" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  # -------------------------------------------------------------------------
  # 409 - State-precondition conflict (delete and set-fallback require DISABLED)
  # -------------------------------------------------------------------------

  @esim_profile_errors_409_01_enabled_profile
  Scenario Outline: <operationId> is rejected when the target eSIM Profile is ENABLED
    Given the resource "/esim-profile-management/vwip/<endpoint>"
    And the request body property "$.esimProfile.iccid" is set to a valid ICCID for an eSIM Profile in ENABLED state
    When the request "<operationId>" is sent
    Then the response status code is 409
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 409
    And the response property "$.code" is "INCOMPATIBLE_STATE"
    And the response property "$.message" contains a user friendly text

    Examples:
      | endpoint     | operationId            |
      | delete       | deleteEsimProfile      |
      | set-fallback | setFallbackEsimProfile |

  # -------------------------------------------------------------------------
  # 422 - Semantic identifier-pairing check
  # -------------------------------------------------------------------------

  @esim_profile_errors_422_01_identifier_mismatch_operation
  Scenario Outline: <operationId> is rejected when the ICCID is not installed on the given EID
    Given the resource "/esim-profile-management/vwip/<endpoint>"
    And the request body property "$.esimProfile.eid" is set to a valid EID
    And the request body property "$.esimProfile.iccid" is set to a valid ICCID that is not installed on that eUICC
    When the request "<operationId>" is sent
    Then the response status code is 422
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 422
    And the response property "$.code" is "ESIM_PROFILE_MANAGEMENT.IDENTIFIER_MISMATCH"
    And the response property "$.message" contains a user friendly text

    Examples:
      | endpoint     | operationId            |
      | enable       | enableEsimProfile      |
      | disable      | disableEsimProfile     |
      | delete       | deleteEsimProfile      |
      | set-fallback | setFallbackEsimProfile |

  @esim_profile_errors_422_02_identifier_mismatch_retrieve_status
  Scenario: Retrieve status is rejected when the ICCID is not installed on the given EID
    Given the resource "/esim-profile-management/vwip/retrieve-status"
    And the request body property "$.esimProfile.eid" is set to a valid EID
    And the request body property "$.esimProfile.iccid" is set to a valid ICCID that is not installed on that eUICC
    When the request "getEsimProfileStatus" is sent
    Then the response status code is 422
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 422
    And the response property "$.code" is "ESIM_PROFILE_MANAGEMENT.IDENTIFIER_MISMATCH"
    And the response property "$.message" contains a user friendly text

  @esim_profile_errors_422_03_service_not_applicable
  Scenario: Set-fallback is rejected when the eSIM Profile cannot serve as a fallback
    Given the resource "/esim-profile-management/vwip/set-fallback"
    And the request body property "$.esimProfile.iccid" is set to a valid ICCID for an eSIM Profile that is not eligible to serve as a fallback
    When the request "setFallbackEsimProfile" is sent
    Then the response status code is 422
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response property "$.status" is 422
    And the response property "$.code" is "SERVICE_NOT_APPLICABLE"
    And the response property "$.message" contains a user friendly text

  # -------------------------------------------------------------------------
  # 200 - Asynchronous FAILED outcome (semantic branch of the async model)
  # -------------------------------------------------------------------------

  @esim_profile_errors_200_01_operation_failed_outcome
  Scenario: Retrieve an operation that completed with a FAILED outcome
    Given an existing operation whose target device was unreachable and which has completed
    And the resource "/esim-profile-management/vwip/operations/{operationId}"
    And the path parameter "operationId" is set to that operation ID
    When the request "retrieveOperation" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/ESimProfileResponse"
    And the response property "$.status" is "COMPLETED"
    And the response property "$.result.outcome" is "FAILED"
    And the response property "$.result.failureReason" exists
