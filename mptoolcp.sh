#!/bin/bash
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
  if [ $dryrun == 0 ]; then
      eval "$cmd"
  fi
}

# set_latency(from, to, lat_ms)
#
#  Sets TAP interface to have a specific amount of delay
#
#  Params:
#  from   - the number of source host
#  to     - the number of destination host
#  lat_ms - latency in ms
#
set_tc_latency(){
  from=$1
  to=$2
  lat_ms=$3
  $cmd="ssh root@${host_prefix}${from} tc qdisc del dev tap${to} root netem; tc qdisc add dev tap${to} root netem delay ${lat_ms}ms"
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
  $cmd="ssh root@${host_prefix}${from} tc qdisc del dev tap${to}"
  run "$cmd"
}

#
# set_mptcp(host STR, setting BOOL)
#
#  Set host's MPTCP enabled/disabled.
#
set_mptcp(){
  host=$1
  setting=$2
  $cmd="ssh root@${host_prefix}${host} echo \"${setting}\" > /proc/sys/net/mptcp/mptcp_enabled"
  run "$cmd"
}

#
# run_iperf(i FLOAT, t FLOAT, p INT, m BOOL, n INT, server STR, filename STR)
#  Run iperf with the following settings. MPTCP and ndiffport options are NOT preserved.
#  If you need mptcp_enabled and mptcp_ndiffports intact, back them up first.
#
#  i = interval of report
#  t = total time
#  p = number of iperf parallel threads
#  m = MPTCP on(1)/off(0)
#  n = MPTCP ndiffports setting
#  server = server's IP address
#  filename = the file name to write to
run_iperf(){
  i=$1
  t=$2
  p=$3
  m=$4
  n=$5
  server=$6
  filename=$7
  if [ $p -eq 1 ];
    then
      iperf -c $server -t $t -i $i -y C -P $p > $filename.csv
    else 
      iperf -c $server -t $t -i $i -y C -P $p | grep ',\-1,' > $filename.csv
  fi
  sleep 2
}


# get old MPTCP setting
echo 'Backing up MPTCP Option'
original_mptcp_setting=`cat /proc/sys/net/mptcp/mptcp_enabled`
original_ndiffports=`sysctl -n net.mptcp.mptcp_ndiffports`

for i in 0 1
do
  echo "$i" > /proc/sys/net/mptcp/mptcp_enabled
  for j in `seq 1 $parallels`
  do
    for k in `seq 1 $tries`
    do
      echo "Testcase: mptcp $i, threads $j, run $k"
      run_iperf $iperf_interval $testtime $j $i 1 $server $file_prefix-$i-$j-$k.csv
    done
    #echo $i $j
    cat /dev/null > $file_prefix-$i-$j.all.csv
    for k in $file_prefix-$i-$j-*.csv
    do
        #tr "\n" "\t"
        #echo $k
        cut -d, -f9 $k | tr "\n" "\t" | sed 's/$/\n/' >> $file_prefix-$i-$j.all.csv ;
        sed -i 's/[ \t]*$//' $file_prefix-$i-$j.all.csv
        python avgcol.py $file_prefix-$i-$j.all.csv | tr '\t' '\n' > $file_prefix-$i-$j.avg.csv
    done
    rm -f $file_prefix-$i-$j-*.csv
  done
done


# restore old MPTCP setting
echo 'Restoring MPTCP Option'
echo "$original_mptcp_setting" > /proc/sys/net/mptcp/mptcp_enabled
eval "sysctl -w net.mptcp.mptcp_ndiffports=$original_ndiffports"

