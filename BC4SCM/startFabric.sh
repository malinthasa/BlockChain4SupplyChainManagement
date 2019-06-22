#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error
set -e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
starttime=$(date +%s)

CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
CC_SRC_PATH=/opt/gopath/src/github.com/SCMlogic/javascript

# clean the keystore
rm -rf ./hfc-key-store

# launch network; create channel and join peer to channel
cd ../network
./start.sh

# Now launch the CLI container in order to install, instantiate chaincode
# and prime the ledger with our 10 cars
docker-compose -f ./docker-compose.yml up -d cli
docker ps -a

docker exec -e "CORE_PEER_LOCALMSPID=IBOMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibo.bc4scm.de/users/Admin@ibo.bc4scm.de/msp" cli peer chaincode install -n SCMlogic -v 1.0 -p "$CC_SRC_PATH" -l "$CC_RUNTIME_LANGUAGE"
docker exec -e "CORE_PEER_LOCALMSPID=IBOMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibo.bc4scm.de/users/Admin@ibo.bc4scm.de/msp" cli peer chaincode instantiate -o orderer.bc4scm.de:7050 -C mychannel -n SCMlogic -l "$CC_RUNTIME_LANGUAGE" -v 1.0 -c '{"Args":[]}' -P "OR ('IBOMSP.member','RetailerMSP.member')"
sleep 10
docker exec -e "CORE_PEER_LOCALMSPID=IBOMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibo.bc4scm.de/users/Admin@ibo.bc4scm.de/msp" cli peer chaincode invoke -o orderer.bc4scm.de:7050 -C mychannel -n SCMlogic -c '{"function":"initLedger","Args":[]}'

cat <<EOF
Total setup execution time : $(($(date +%s) - starttime)) secs ...
EOF
