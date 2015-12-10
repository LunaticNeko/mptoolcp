#!/bin/bash

# These are defaults to trap some errors. Do not edit.
dryrun=1

source mptoolcp_config.sh

# run(cmd)
#  Executes the specified command if dryrun is not set
#
#  Params:
#  cmd - The command to be executed
#
run(){
  cmd="$1"
  echo "$cmd"
  if [ $dryrun -eq 0 ]; then
      eval "$cmd"
  fi
}

# set_tc_delay(from, to, lat_ms)
#
#  Sets TAP interface to have a specific amount of delay
#
#  Params:
#  from   - the number of source host
#  to     - the number of destination host
#  lat_ms - latency in ms
#
set_tc_delay(){
  from=$1
  to=$2
  lat_ms=$3
  cmd="ssh root@${host_prefix}${from} tc qdisc del dev tap${to} root netem; tc qdisc add dev tap${to} root netem delay ${lat_ms}ms"
  run "$cmd"
}

# clear_tc(from, to)
#  Clears tc settings from $1 to $2
#
#  from - Source Host
#  to   - Destnation Host
#
clear_tc(){
  from=$1
  to=$2
  cmd="ssh root@${host_prefix}${from} tc qdisc del dev tap${to}"
  run "$cmd"
}

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
  sleep 2
}

#
# process_logs(prefix STR, ext STR, delete_original BOOL)
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
    ext=$2
    delete_original=$3
    files=`ls ${prefix}*.$ext`
    echo "Procesing ${files}"
    for f in files; do
        cut -d, -f9 $k | tr "\n" "\t" | sed 's/$/\n/' >> $prefix.all.$ext
        sed -i 's/[ \t]*$//' $prefix.all.$ext
        python avgcol.py $prefix.all.$ext | tr "\t" "\n" > $prefix.avg.$ext
    done
    if [ $delete_original -eq 1 ]; then
        rm -f files
    fi
}

# get old MPTCP setting
echo 'Backing up MPTCP Option'
original_mptcp_setting=`sysctl -n net.mptcp.mptcp_enabled`
original_ndiffports=`sysctl -n net.mptcp.mptcp_ndiffports`

for delay in `seq 0 10 150`;do
    set_tc_delay 1 2 ${delay}
    for ports in `seq 1 8`; do
        set_mptcp_ndiffports ${ports}
        for i in `seq 1 $tries`; do
            echo "Testcase: ${delay}ms, n=${ports}, #$i"
            run_iperf $iperf_interval $testtime 1 $server $file_prefix-$delay-$ports-$i.csv
        done
        process_logs $file_prefix-$delay-$ports- csv 1
    done
done



#for i in 0 1
#do
#  set_mptcp_enabled $i
#  for j in `seq 1 $parallels`
#  do
#    for k in `seq 1 $tries`
#    do
#      echo "Testcase: mptcp $i, threads $j, run $k"
#      run_iperf $iperf_interval $testtime $j $i 1 $server $file_prefix-$i-$j-$k.csv
#    done
#    #echo $i $j
#    cat /dev/null > $file_prefix-$i-$j.all.csv
#    for k in $file_prefix-$i-$j-*.csv
#    do
#        #tr "\n" "\t"
#        #echo $k
#        cut -d, -f9 $k | tr "\n" "\t" | sed 's/$/\n/' >> $file_prefix-$i-$j.all.csv ;
#        sed -i 's/[ \t]*$//' $file_prefix-$i-$j.all.csv
#        python avgcol.py $file_prefix-$i-$j.all.csv | tr '\t' '\n' > $file_prefix-$i-$j.avg.csv
#    done
#    rm -f $file_prefix-$i-$j-*.csv
#  done
#done

# restore old MPTCP setting
echo 'Restoring MPTCP Option'
eval "sysctl -w net.mptcp.mptcp_ndiffports=$original_ndiffports"
eval "sysctl -w net.mptcp.mptcp_enabled=$original_mptcp_setting"

