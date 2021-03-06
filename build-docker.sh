#!/bin/bash -e
PRESERVE_CONTAINER=1

BUILD_OPTS="$*"

DOCKER="docker"
set +e
if ! $DOCKER ps >/dev/null 2>&1; then
	DOCKER="sudo docker"
fi
if ! $DOCKER ps >/dev/null; then
	echo "error connecting to docker:"
	$DOCKER ps
	exit 1
fi
set -e

if [ -f config ]; then
	# shellcheck disable=SC1091
	source config
fi

while getopts "c:" flag
do
	case "$flag" in
		c)
			# shellcheck disable=SC1090
			source "$OPTARG"
			;;
		*)
			;;
	esac
done

CONTAINER_NAME=${CONTAINER_NAME:-pigen_work}
CONTINUE=${CONTINUE:-0}
PRESERVE_CONTAINER=${PRESERVE_CONTAINER:-0}

if [ -z "${IMG_NAME}" ]; then
	echo "IMG_NAME not set in 'config'" 1>&2
	echo 1>&2
exit 1
fi

CONTAINER_EXISTS=$($DOCKER ps -a --filter name="$CONTAINER_NAME" -q)
CONTAINER_RUNNING=$($DOCKER ps --filter name="$CONTAINER_NAME" -q)
if [ "$CONTAINER_RUNNING" != "" ]; then
	echo "The build is already running in container $CONTAINER_NAME. Aborting."
	exit 1
fi
if [ "$CONTAINER_EXISTS" != "" ] && [ "$CONTINUE" != "1" ]; then
	echo "Container $CONTAINER_NAME already exists and you did not specify CONTINUE=1. Aborting."
	echo "You can delete the existing container like this:"
	echo "  $DOCKER rm -v $CONTAINER_NAME"
	exit 1
fi

$DOCKER build -t pi-gen .
if [ "$CONTAINER_EXISTS" != "" ]; then
	trap 'echo "got CTRL+C... please wait 5s"; $DOCKER stop -t 5 ${CONTAINER_NAME}_cont' SIGINT SIGTERM
	time $DOCKER run --rm --privileged \
		--volumes-from="${CONTAINER_NAME}" --name "${CONTAINER_NAME}_cont" \
		pi-gen \
		bash -e -o pipefail -c "dpkg-reconfigure qemu-user-static &&
	cd /pi-gen; ./build.sh ${BUILD_OPTS} ;
	rsync -av work/*/build.log deploy/" &
	wait "$!"
else
	trap 'echo "got CTRL+C... please wait 5s"; $DOCKER stop -t 5 ${CONTAINER_NAME}' SIGINT SIGTERM
	time $DOCKER run --name "${CONTAINER_NAME}" --privileged \
		pi-gen \
		bash -e -o pipefail -c "dpkg-reconfigure qemu-user-static &&
	cd /pi-gen; ./build.sh ${BUILD_OPTS} &&
	rsync -av work/*/build.log deploy/" &
	wait "$!"
fi
echo "copying results from deploy/"
$DOCKER cp "${CONTAINER_NAME}":/pi-gen/deploy .
ls -lah deploy

# cleanup
if [ "$PRESERVE_CONTAINER" != "1" ]; then
	$DOCKER rm -v "$CONTAINER_NAME"
fi

echo "Done! Your image(s) should be in deploy/"
