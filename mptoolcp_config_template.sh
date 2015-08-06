#!/bin/bash

# the correct config file name is mptoolcp_config.sh
# all variables are required

# The address of the server
server=10.0.0.1

# The number of runs to execute per configuration
tries=10

# The length of time for each iperf run (seconds)
testtime=10

# The number of maximum iperf threads to run in parallel
parallels=1

# Should we collect data in intervals? And the period of the interval.
use_interval=1
iperf_interval=0.5

# Finally, give the prefix for the CSV files.
prefix=smoci6
