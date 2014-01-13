#!/usr/bin/env bash

IMG_FILES="images/continuous-paper.jpg images/debian-logo-500x242.jpg
images/raspbian-logo-400x234.jpg images/ubuntu-logo-400x283.png
images/mopi/prototype-regulator-05.jpg
images/mopi/thumbs/prototype-regulator-05.jpg images/wiring-pi-bbd.jpg
images/wiring-pi-bbd-500x295.jpg"

ART=packaging-jan-2014
tar cvzf ${ART}.tgz ${ART}* ${IMG_FILES}
