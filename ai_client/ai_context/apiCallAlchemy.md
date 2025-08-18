# EXAMPLE REQUEST

https://eth-mainnet.g.alchemy.com/v2/:apiKey

curl -X POST https://eth-mainnet.g.alchemy.com/v2/{apiKey} \
     -H "Content-Type: application/json" \
     -d '{
  "jsonrpc": "2.0",
  "method": "alchemy_getAssetTransfers",
  "params": [
    "0x0",
    "0x0000000000000000000000000000000000000000",
    "0x5c43B1eD97e52d009611D89b74fA829FE4ac56b1",
    true,
    [
      "erc20"
      "erc721",
      "erc1155"
    ]
  ],
  "id": 1
}'


# EXAMPLE RESPONSE 
{
  "jsonrpc": "2.0",
  "id": "1",
  "result": {
    "transfers": [
      {
        "blockNum": "0xb0eadc",
        "uniqueId": "0x3847245c01829b043431067fb2bfa95f7b5bdc7e4246c843e7a573ab6f26f5ff:external",
        "hash": "0x3847245c01829b043431067fb2bfa95f7b5bdc7e4246c843e7a573ab6f26f5ff",
        "from": "0xef4396d9ff8107086d215a1c9f8866c54795d7c7",
        "to": "0x5c43b1ed97e52d009611d89b74fa829fe4ac56b1",
        "value": 0.5,
        "erc721TokenId": null,
        "erc1155Metadata": null,
        "tokenId": null,
        "asset": "ETH",
        "category": "external",
        "rawContract": {
          "value": "0x6f05b59d3b20000",
          "address": null,
          "decimal": "0x12"
        }
      },
      {
        "blockNum": "0xb96042",
        "uniqueId": "0x5c88806ce2e4a42c5fbd5804f340ed887995914546cf92ec39eb5472cf22c88c:external",
        "hash": "0x5c88806ce2e4a42c5fbd5804f340ed887995914546cf92ec39eb5472cf22c88c",
        "from": "0xef4396d9ff8107086d215a1c9f8866c54795d7c7",
        "to": "0x5c43b1ed97e52d009611d89b74fa829fe4ac56b1",
        "value": 0.27,
        "erc721TokenId": null,
        "erc1155Metadata": null,
        "tokenId": null,
        "asset": "ETH",
        "category": "external",
        "rawContract": {
          "value": "0x3bf3b91c95b0000",
          "address": null,
          "decimal": "0x12"
        }
      }
    ],
    "pageKey": ""
  }
}