#!/bin/bash
server=10.0.1.5
tries=10
testtime=240
parallels=1
#delays=$(seq 20 20 100; seq 110 10 200)
#delays=$(seq 90 10 150)
delays=$(seq 0 10 200)
ports="1 2 4 8 12 16 20 24"
use_interval=1
iperf_interval=0.5
file_prefix=lat-sm-1pv2
host_prefix="sd-ofex-"
nhosts=6
host=1 #FAILSAFE/UNSAFE: To prevent catastrophes, $host variable refs shall default to this.
dryrun=0
