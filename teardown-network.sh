#!/usr/bin/env bash


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

echo "===> Cleaning up any leftover runs of hyperledger"
cd test-network
./network.sh down
docker stop $(docker ps -q -a)
docker rm $(docker ps -q -a)
docker rmi -f $(docker ps -q -a)

docker image list

echo "===> Done"
