#!/usr/bin/env bash

cd /grist
mv ${1} "${1}.grist"
yarn cli history prune "${1}.grist" 10
mv "${1}.grist" ${1}
rm -rf /tmp/*-backup.grist
rm -rf /tmp/yarn--*
