#!/usr/bin/bash

# Script to test CentOS upgrades.
#
# start: 8.0
# end: 8 Stream
# group: server

###############
# shell setup #
###############

# exit on any non-zero exit status
set -e

# exit on any unset variables
set -u

# prevent errors in a pipeline from being masked
set -o pipefail

#################
# buildah steps #
#################

# print commands
set -x

# base image
# TODO: switch to 8.0 tag once it exists
CONTAINER=$(buildah from --pull-always centos:8)
buildah run $CONTAINER -- dnf --assumeyes update

# install group
buildah run $CONTAINER -- dnf --assumeyes swap coreutils-single coreutils
buildah run $CONTAINER -- dnf --assumeyes group install server

# switch to stream
buildah run $CONTAINER -- dnf --assumeyes install dnf-plugins-core centos-release-stream
buildah run $CONTAINER -- dnf config-manager --disable BaseOS --disable AppStream --disable extras
buildah run $CONTAINER -- dnf --assumeyes update

# remove dnf cache
buildah run $CONTAINER -- dnf clean all
buildah run $CONTAINER -- find /var/cache/dnf -mindepth 1 -delete

# save image
TAG=8-stream-server
buildah commit $CONTAINER centos-qa:$TAG
buildah rm $CONTAINER

# disable printing commands
set +x

#####################
# image run example #
#####################

cat << EOF

Build complete.  To run image for inspection, run this command:

    podman run -it --rm centos-qa:$TAG

EOF
