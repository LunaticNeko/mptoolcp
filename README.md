# mptoolcp
MPToolCP: MPTCP Performance Tool, Crappily Programmed

What does it do?
====

Measures and analyzes MPTCP performance between where you are right now and any iperf server you want.
Produces many CSV files that you can play with.

Requirements
====

* Python 2.7 (or 2.x with argparse)
* iperf
* MPTCP (actually you can run this in no-MPTCP mode. This tool is still useful as iperf automation tool.)
** Note that MPTCP must be installed. Otherwise you will get an error when I try to enable/disable MPTCP.

CSV files?
====

Actually "tab-separated" files. There are three kinds of files:
* **PREFIX-i-j-k.csv** are raw CSV from iperf.
* **PREFIX-i-j.all.csv** are the previous files combined into a single file.
* **PREFIX-i-j.avg.csv** are the files that should be useful to you. It still doesn't give you the time points
however so you have to add that yourself.

How to use
====

Find the loop starting point (for i in 0 1) for MPTCP-ness test.

Adjust parameters as necessary.

Run the sh script.
