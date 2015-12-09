#!/bin/bash
server=10.0.1.6
tries=40
testtime=20
parallels=4
use_interval=1
iperf_interval=0.5
file_prefix=stj6
host_prefix="sd-ofex-"
nhosts=6
host=1 #FAILSAFE/UNSAFE: To prevent catastrophes, $host variable refs shall default to this.
