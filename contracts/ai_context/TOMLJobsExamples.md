# GET > String 

type = "directrequest"
# evmChainID for Sepolia Testnet
evmChainID = "11155111"
schemaVersion = 1
name = "Get > String"
contractAddress = "YOUR_ORACLE_CONTRACT_ADDRESS"
maxTaskDuration = "0s"
minIncomingConfirmations = 0
observationSource = """
    decode_log   [type="ethabidecodelog"
                  abi="OracleRequest(bytes32 indexed specId, address requester, bytes32 requestId, uint256 payment, address callbackAddr, bytes4 callbackFunctionId, uint256 cancelExpiration, uint256 dataVersion, bytes data)"
                  data="$(jobRun.logData)"
                  topics="$(jobRun.logTopics)"]

    decode_cbor  [type="cborparse" data="$(decode_log.data)"]
    fetch        [type="http" method=GET url="$(decode_cbor.get)" allowUnrestrictedNetworkAccess="true"]
    parse        [type="jsonparse" path="$(decode_cbor.path)" data="$(fetch)"]
    encode_data  [type="ethabiencode" abi="(bytes32 requestId, string value)" data="{ \\"requestId\\": $(decode_log.requestId), \\"value\\": $(parse) }"]
    encode_tx    [type="ethabiencode"
                  abi="fulfillOracleRequest2(bytes32 requestId, uint256 payment, address callbackAddress, bytes4 callbackFunctionId, uint256 expiration, bytes calldata data)"
                  data="{\\"requestId\\": $(decode_log.requestId), \\"payment\\":   $(decode_log.payment), \\"callbackAddress\\": $(decode_log.callbackAddr), \\"callbackFunctionId\\": $(decode_log.callbackFunctionId), \\"expiration\\": $(decode_log.cancelExpiration), \\"data\\": $(encode_data)}"
                  ]
    submit_tx    [type="ethtx" to="YOUR_ORACLE_CONTRACT_ADDRESS" data="$(encode_tx)"]

    decode_log -> decode_cbor -> fetch -> parse -> encode_data -> encode_tx -> submit_tx
"""

# GET > Uint256 

type = "directrequest"
schemaVersion = 1
name = "Get > Uint256 - (TOML)"
maxTaskDuration = "0s"
contractAddress = "YOUR_ORACLE_CONTRACT_ADDRESS"
minIncomingConfirmations = 0
observationSource = """
    decode_log   [type="ethabidecodelog"
                  abi="OracleRequest(bytes32 indexed specId, address requester, bytes32 requestId, uint256 payment, address callbackAddr, bytes4 callbackFunctionId, uint256 cancelExpiration, uint256 dataVersion, bytes data)"
                  data="$(jobRun.logData)"
                  topics="$(jobRun.logTopics)"]

    decode_cbor  [type="cborparse" data="$(decode_log.data)"]
    fetch        [type="http" method=GET url="$(decode_cbor.get)" allowUnrestrictedNetworkAccess="true"]
    parse        [type="jsonparse" path="$(decode_cbor.path)" data="$(fetch)"]

    multiply     [type="multiply" input="$(parse)" times="$(decode_cbor.times)"]

    encode_data  [type="ethabiencode" abi="(bytes32 requestId, uint256 value)" data="{ \\"requestId\\": $(decode_log.requestId), \\"value\\": $(multiply) }"]
    encode_tx    [type="ethabiencode"
                  abi="fulfillOracleRequest2(bytes32 requestId, uint256 payment, address callbackAddress, bytes4 callbackFunctionId, uint256 expiration, bytes calldata data)"
                  data="{\\"requestId\\": $(decode_log.requestId), \\"payment\\":   $(decode_log.payment), \\"callbackAddress\\": $(decode_log.callbackAddr), \\"callbackFunctionId\\": $(decode_log.callbackFunctionId), \\"expiration\\": $(decode_log.cancelExpiration), \\"data\\": $(encode_data)}"
                  ]
    submit_tx    [type="ethtx" to="YOUR_ORACLE_CONTRACT_ADDRESS" data="$(encode_tx)"]

    decode_log -> decode_cbor -> fetch -> parse -> multiply -> encode_data -> encode_tx -> submit_tx
"""

# MultiWord example 

type = "directrequest"
schemaVersion = 1
name = "multi-word (TOML)"
maxTaskDuration = "0s"
contractAddress = "YOUR_ORACLE_CONTRACT_ADDRESS"
minIncomingConfirmations = 0
observationSource = """
       decode_log   [type="ethabidecodelog"
                  abi="OracleRequest(bytes32 indexed specId, address requester, bytes32 requestId, uint256 payment, address callbackAddr, bytes4 callbackFunctionId, uint256 cancelExpiration, uint256 dataVersion, bytes data)"
                  data="$(jobRun.logData)"
                  topics="$(jobRun.logTopics)"]
    decode_cbor  [type="cborparse" data="$(decode_log.data)"]
    decode_log -> decode_cbor
    decode_cbor -> btc
    decode_cbor -> usd
    decode_cbor -> eur
    btc          [type="http" method=GET url="$(decode_cbor.urlBTC)" allowunrestrictednetworkaccess="true"]
    btc_parse    [type="jsonparse" path="$(decode_cbor.pathBTC)" data="$(btc)"]
    btc_multiply [type="multiply" input="$(btc_parse)", times="100000"]
    btc -> btc_parse -> btc_multiply
    usd          [type="http" method=GET url="$(decode_cbor.urlUSD)" allowunrestrictednetworkaccess="true"]
    usd_parse    [type="jsonparse" path="$(decode_cbor.pathUSD)" data="$(usd)"]
    usd_multiply [type="multiply" input="$(usd_parse)", times="100000"]
    usd -> usd_parse -> usd_multiply
    eur          [type="http" method=GET url="$(decode_cbor.urlEUR)" allowunrestrictednetworkaccess="true"]
    eur_parse    [type="jsonparse" path="$(decode_cbor.pathEUR)" data="$(eur)"]
    eurs_multiply [type="multiply" input="$(eur_parse)", times="100000"]
    eur -> eur_parse -> eurs_multiply
    btc_multiply -> encode_mwr
    usd_multiply -> encode_mwr
    eurs_multiply -> encode_mwr
    // MWR API does NOT auto populate the requestID.
    encode_mwr [type="ethabiencode"
                abi="(bytes32 requestId, uint256 _btc, uint256 _usd, uint256 _eurs)"
                data="{\\"requestId\\": $(decode_log.requestId), \\"_btc\\": $(btc_multiply), \\"_usd\\": $(usd_multiply), \\"_eurs\\": $(eurs_multiply)}"
                ]
    encode_tx  [type="ethabiencode"
                abi="fulfillOracleRequest2(bytes32 requestId, uint256 payment, address callbackAddress, bytes4 callbackFunctionId, uint256 expiration, bytes calldata data)"
                data="{\\"requestId\\": $(decode_log.requestId), \\"payment\\":   $(decode_log.payment), \\"callbackAddress\\": $(decode_log.callbackAddr), \\"callbackFunctionId\\": $(decode_log.callbackFunctionId), \\"expiration\\": $(decode_log.cancelExpiration), \\"data\\": $(encode_mwr)}"
                ]
    submit_tx  [type="ethtx" to="YOUR_ORACLE_CONTRACT_ADDRESS" data="$(encode_tx)"]
    encode_mwr -> encode_tx -> submit_tx
"""

# HTTP task 

HTTP tasks make HTTP requests to arbitrary URLs.

Parameters

method: the HTTP method that the request should use.
url: the URL to make the HTTP request to.
requestData (optional): a statically-defined payload to be sent to the external adapter.
allowUnrestrictedNetworkAccess (optional): permits the task to access a URL at localhost, which could present a security risk. Note that Bridge tasks allow this by default.
headers (optional): an array of strings. The number of strings must be even. Example: foo [type=http headers="[\\"X-Header-1\\", \\"value1\\", \\"X-Header-2\\", \\"value2\\"]"]
Outputs

A string containing the response body.

Example

copy to clipboard
my_http_task [type="http"
              method=PUT
              url="http://chain.link"
              requestData="{\\"foo\\": $(foo), \\"bar\\": $(bar), \\"jobID\\": 123}"
              allowUnrestrictedNetworkAccess=true
              ]
