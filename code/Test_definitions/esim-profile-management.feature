Feature: CAMARA eSIM Profile Management API, v0.1.0-rc.1 - Happy Path
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  #
  # Testing assets:
  # * A valid EID for a device with an eUICC
  # * A valid activation code for downloading an eSIM Profile
  # * A valid ICCID for an existing downloaded eSIM Profile (disabled state)
  # * A valid ICCID for an existing enabled eSIM Profile
  # * A valid operationId from a previously submitted operation
  #
  # References to OAS spec schemas refer to schemas specified in esim-profile-management.yaml

  Background: Common eSIM Profile Management setup
    Given an environment at "apiRoot"
    And the header "Authorization" is set to a valid access token
    And the header "Content-Type" is set to "application/json"
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"

  # Success scenarios for POST /download

  @esim_profile_download_01_success
  Scenario: Download eSIM Profile to device
    Given the resource "/esim-profile-management/v0.1rc1/download"
    And the request body is set to a request body compliant with the schema at "/components/schemas/DownloadEsimProfileRequest"
    And the request body property "$.esimProfile.eid" is set to a valid EID
    And the request body property "$.activationCode" is set to a valid activation code
    When the request "downloadEsimProfile" is sent
    Then the response status code is 202
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/ESimProfileResponse"
    And the response property "$.operationId" exists
    And the response property "$.operation" is "download"
    And the response property "$.status" is "accepted"
    And the response property "$.esimProfile.eid" has the same value as the request body property "$.esimProfile.eid"

  # Success scenarios for POST /enable, /disable, /delete, /set-fallback

  @esim_profile_iccidOperation_01_success
  Scenario Outline: Successful <operation> of eSIM Profile
    Given the resource "/esim-profile-management/v0.1rc1/<endpoint>"
    And the request body property "$.esimProfile.iccid" is set to a valid ICCID
    When the request "<operationId>" is sent
    Then the response status code is 202
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/ESimProfileResponse"
    And the response property "$.operationId" exists
    And the response property "$.operation" is "<operation>"
    And the response property "$.status" is "accepted"
    And the response property "$.esimProfile.iccid" has the same value as the request body property "$.esimProfile.iccid"

    Examples:
      | endpoint     | operationId            | operation    |
      | enable       | enableEsimProfile      | enable       |
      | disable      | disableEsimProfile     | disable      |
      | delete       | deleteEsimProfile      | delete       |
      | set-fallback | setFallbackEsimProfile | set-fallback |

  # Success scenarios for POST /retrieve-status

  @esim_profile_retrieveStatus_01_success
  Scenario Outline: Retrieve eSIM Profile status by <identifier_type>
    Given the resource "/esim-profile-management/v0.1rc1/retrieve-status"
    And the request body property "$.esimProfile.<identifier_field>" is set to a valid <identifier_type>
    When the request "getEsimProfileStatus" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/EsimProfileStatusResponse"
    And the response property "$.esimProfiles" is an array with at least 1 item

    Examples:
      | identifier_type | identifier_field |
      | EID             | eid              |
      | ICCID           | iccid            |

  # Success scenarios for GET /operations/{operationId}

  @esim_profile_retrieveOperation_01_success
  Scenario: Retrieve operation information
    Given an existing operation from a previous eSIM Profile request
    And the resource "/esim-profile-management/v0.1rc1/operations/{operationId}"
    And the path parameter "operationId" is set to an existing operation ID
    When the request "retrieveOperation" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has the same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/ESimProfileResponse"
    And the response property "$.operationId" is equal to the path parameter "operationId"
    And the response property "$.operation" exists
    And the response property "$.status" exists
