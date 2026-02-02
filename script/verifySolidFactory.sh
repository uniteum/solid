contract=$(jq -r '.transactions[0].contractAddress' broadcast/SolidFactory.s.sol/$chain/run-latest.json)
args=$(cast abi-encode "constructor(address)" $(jq -r '.transactions[].arguments[0]' broadcast/SolidFactory.s.sol/$chain/run-latest.json))
forge verify-contract $contract SolidFactory --chain $chain --verifier etherscan --show-standard-json-input > script/SolidFactory.json
