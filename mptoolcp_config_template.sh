#!/bin/bash
server=10.0.1.1
tries=10
testtime=10
parallels=2
use_interval=1
iperf_interval=1
file_prefix=test
host_prefix="host-"
nhosts=6
host=1 #FAILSAFE/UNSAFE: To prevent catastrophes, $host variable refs shall default to this.
