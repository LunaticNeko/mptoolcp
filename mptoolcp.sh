#!/bin/bash

# These are defaults to trap some errors. Do not edit.
dryrun=1

mptoolcp_dir="$(dirname "$0")"
setup_gre_dir="$(dirname "$0")"
parent_path=$( cd "$(dirname "${BASH_SOURCE}")" ; pwd -P )

source ${parent_path}/mptoolcp_config.sh
source ${parent_path}/../../setup_gre/setup_gre.sh

#
# set_mptcp_enabled(setting BOOL)
#
#  Set MPTCP enabled/disabled.
#
set_mptcp_enabled(){
  cmd="sysctl -w net.mptcp.mptcp_enabled=$1"
  run "$cmd"
}

#
# set_mptcp_ndiffports(ndiffports INT)
#
#  Set MPTCP ndiffports value
#
set_mptcp_ndiffports(){
  #ndiffports must never be set to zero
  if [ $1 -eq 0 ];
  then
    exit 1
  fi
  cmd="sysctl -w net.mptcp.mptcp_ndiffports=$1"
  run "$cmd"
}

#
# run_iperf(i FLOAT, t FLOAT, p INT, server STR, filename STR)
#  Run iperf with the following settings. MPTCP and ndiffport options are NOT preserved.
#  If you need mptcp_enabled and mptcp_ndiffports intact, back them up first.
#
#  iperf_i = interval of report
#  iperf_t = total time
#  iperf_p = number of iperf parallel threads
#  server = server's IP address
#  filename = the file name to write to
run_iperf(){
  iperf_i=$1
  iperf_t=$2
  iperf_p=$3
  server=$4
  filename=$5
  if [ $iperf_p -eq 1 ];
    then
      iperf -c $server -t $iperf_t -i $iperf_i -y C -P $iperf_p > $filename
    else 
      iperf -c $server -t $iperf_t -i $iperf_i -y C -P $iperf_p | grep ',\-1,' > $filename
  fi
  sleep 1
}

#
# process_logs(prefix STR, start INT, end INT, ext STR, delete_original BOOL)
#
#  Processes log files generated with run_iperf command.
#  Two files are produced: all and avg.
#  all file is a file that lists all runs grouped together. Each line is a run, and each
#    column is a transient data value.
#  avg file is a file that lists average of all runs. It has one column, and each time point is
#    in rows.
#  If there are unequal number of data points between runs, avg file will not be produced.
#  You should fix it.
#
#  prefix = Prefix part of file name
#  ext = Desired extension of file name, no leading dot please
#  delete_original = Set to 1 to delete processed files (they will be deleted
#                    INDISCRIMINATELY by the prefix w/o warning. Be careful!
#
process_logs(){
    prefix=$1
    start=$2
    end=$3
    ext=$4
    delete_original=$5
    files=`ls ${prefix}*.$ext`
    echo "Procesing ${files}"
    #for i in `seq ${start} ${end}`; do
    #    cut -d, -f9 ${prefix}$i.${ext} | tr "\n" "\t" | sed 's/$/\n/' >> $prefix.all.$ext
    #done
    #sed -i 's/[ \t]*$//' $prefix.all.$ext
    python avgcol.py --pctrim 33 $prefix.all.$ext | tr "\t" "\n" > $prefix.avg.$ext
    if [ $delete_original -eq 1 ]; then
        for i in `seq ${start} ${end}`; do
            rm -f ${prefix}$i.${ext}
        done
    fi
}

# get old MPTCP setting
echo 'Backing up MPTCP Option'
original_mptcp_setting=`sysctl -n net.mptcp.mptcp_enabled`
original_ndiffports=`sysctl -n net.mptcp.mptcp_ndiffports`
prefix=${host_prefix}

for delay in ${delays}; do
    set_tc_duplex 1 5 ${delay} 100000
    for port in ${ports}; do
        set_mptcp_ndiffports ${port}
        for i in `seq 1 $tries`; do
            # Run a testcase, grab only 
            echo -n "Testcase: ${delay}ms, n=${port}, #$i ... "
            run_iperf $iperf_interval $testtime 1 $server $file_prefix-$delay-$port-$i.csv
            echo $(cut -d, -f9 $file_prefix-$delay-$port-$i.csv | tail -n 1)
            cut -d, -f9 $file_prefix-$delay-$port-$i.csv | tr "\n" "\t" | sed 's/$/\n/' >> $file_prefix-$delay-$port-.all.csv
            sed -i 's/[ \t]*$//' $file_prefix-$delay-$port-.all.csv
        done
        process_logs "$file_prefix-$delay-$port-" 1 $tries csv 1
    done
done

# restore old MPTCP setting
echo 'Restoring MPTCP Option'
eval "sysctl -w net.mptcp.mptcp_ndiffports=$original_ndiffports"
eval "sysctl -w net.mptcp.mptcp_enabled=$original_mptcp_setting"

