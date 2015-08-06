#!/bin/bash
source mptoolcp_config.sh

# get old MPTCP setting
echo 'Backing up MPTCP Option'
original_mptcp_setting=`cat /proc/sys/net/mptcp/mptcp_enabled`

for i in 0 1
do
  echo "$i" > /proc/sys/net/mptcp/mptcp_enabled
  for j in `seq 1 $parallels`
  do
    for k in `seq 1 $tries`
    do
      echo "Testcase: mptcp $i, threads $j, run $k"
      if [ $use_interval -eq 1 ];
      then
        if [ $j -eq 1 ];
        then
          iperf -c $server -t $testtime -i $iperf_interval -y C -P $j > $prefix-$i-$j-$k.csv
        else 
          iperf -c $server -t $testtime -i $iperf_interval -y C -P $j | grep ',\-1,' > $prefix-$i-$j-$k.csv
        fi
      else
        if [ $j -eq 1];
        then
          iperf -c $server -t $testtime -y C -P $j > $prefix-$i-$j-$k.csv
        else
          iperf -c $server -t $testtime -y C -P $j | grep ',\-1,' > $prefix-$i-$j-$k.csv
        fi
      fi
      sleep 2
    done
    #echo $i $j
    cat /dev/null > $prefix-$i-$j.all.csv
    for k in $prefix-$i-$j-*.csv
    do
        #tr "\n" "\t"
        #echo $k
        cut -d, -f9 $k | tr "\n" "\t" | sed 's/$/\n/' >> $prefix-$i-$j.all.csv ;
        sed -i 's/[ \t]*$//' $prefix-$i-$j.all.csv
        python avgcol.py $prefix-$i-$j.all.csv | tr '\t' '\n' > $prefix-$i-$j.avg.csv
    done
    rm -f $prefix-$i-$j-*.csv
  done
done


# restore old MPTCP setting
echo 'Restoring MPTCP Option'
echo "$original_mptcp_setting" > /proc/sys/net/mptcp/mptcp_enabled

