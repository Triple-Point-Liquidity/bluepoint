#!/usr/bin/env bash

# culled from `curl -sSL https://bit.ly/2ysbOFE`

VERSION=2.3.3
CA_VERSION=1.5.2

ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')")
MARCH=$(uname -m)

dockerPull() {
    #three_digit_image_tag is passed in, e.g. "1.4.7"
    three_digit_image_tag=$1
    shift
    #two_digit_image_tag is derived, e.g. "1.4", especially useful as a local tag for two digit references to most recent baseos, ccenv, javaenv, nodeenv patch releases
    two_digit_image_tag=$(echo "$three_digit_image_tag" | cut -d'.' -f1,2)
    while [[ $# -gt 0 ]]
    do
        image_name="$1"
        echo "====> hyperledger/fabric-$image_name:$three_digit_image_tag"
        docker pull "hyperledger/fabric-$image_name:$three_digit_image_tag"
        docker tag "hyperledger/fabric-$image_name:$three_digit_image_tag" "hyperledger/fabric-$image_name"
        docker tag "hyperledger/fabric-$image_name:$three_digit_image_tag" "hyperledger/fabric-$image_name:$two_digit_image_tag"
        shift
    done
}


# This will download the .tar.gz
download() {
    local BINARY_FILE=$1
    local URL=$2
    echo "===> Downloading: " "${URL}"
    curl -L --retry 5 --retry-delay 3 "${URL}" | tar xz || rc=$?
    if [ -n "$rc" ]; then
        echo "==> There was an error downloading the binary file."
        return 22
    else
        echo "==> Done."
    fi
}


# Start here
echo "===> Starting"
if [ "${MARCH}" == "arm64" ]; then
    echo "===> Running on Apple Silicon"
    echo "Run "
    echo "  /usr/bin/arch -x86_64 /bin/zsh --login"
    echo "before re-running this script"
    exit 1
else
    echo "\$MARCH is $MARCH. Good"
fi

echo "===> Setting PATH"
export PATH="${PATH}:$(PWD)/bin"
echo "fabric-ca-server is at $(which fabric-ca-server)"

: "${CA_TAG:="$CA_VERSION"}"
: "${FABRIC_TAG:="$VERSION"}"
: "${THIRDPARTY_TAG:="$THIRDPARTY_IMAGE_VERSION"}"

BINARY_FILE=hyperledger-fabric-${ARCH}-${VERSION}.tar.gz
CA_BINARY_FILE=hyperledger-fabric-ca-${ARCH}-${CA_VERSION}.tar.gz

# pullBinaries
echo "===> Downloading version ${FABRIC_TAG} platform specific Hyperledger Fabric binaries"
download "${BINARY_FILE}" "https://github.com/hyperledger/fabric/releases/download/v${VERSION}/${BINARY_FILE}"
if [ $? -eq 22 ]; then
    echo "------> ${FABRIC_TAG} platform specific fabric binary is not available to download <----"
    echo
    exit
fi

echo "===> Downloading version ${CA_TAG} platform specific Hyperledger fabric-ca-client binary"
download "${CA_BINARY_FILE}" "https://github.com/hyperledger/fabric-ca/releases/download/v${CA_VERSION}/${CA_BINARY_FILE}"
if [ $? -eq 22 ]; then
    echo "------> ${CA_TAG} fabric-ca-client binary is not available to download  (Available from 1.1.0-rc1) <----"
    echo
    exit
fi

echo "===> Pulling Hyperledger Fabric Images"
FABRIC_IMAGES=(peer orderer ccenv tools baseos)
echo "FABRIC_IMAGES:" "${FABRIC_IMAGES[@]}"
dockerPull "${FABRIC_TAG}" "${FABRIC_IMAGES[@]}"

echo "===> Pulling Fabric Certificate Authority Image"
CA_IMAGE=(ca)
dockerPull "${CA_TAG}" "${CA_IMAGE[@]}"
echo "===> Listing out Hyperledger Docker images"
docker images | grep hyperledger

echo "===> Cleaning up any leftover runs of hyperledger"
cd test-network
./network.sh down
docker ps -a -q

echo "===> Booting with CAs not cryptogen"
./network.sh up createChannel -ca

echo "===> Deploying chaincode"
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go

echo "===> Done"
