'''
Average all columns from a CSV.
(Now it's median, just in case)
'''

import numpy
import argparse
import csv
import sys

parser = argparse.ArgumentParser(description="Averages columns from a CSV-like file")
parser.add_argument('filename', type=str, nargs=1)
parser.add_argument('--delim', type=str, default='\t')
parser.add_argument('--med', dest='median', action='store_true')
parser.add_argument('--max', dest='findmax', action='store_true')
parser.add_argument('--pctrim', type=int, default=0) #percent to trim (5 = trim 5% top and 5% bottom)

args = parser.parse_args()

if args.pctrim > 50:
    print "Error: pctrim > 50 (must be <= 50)"
    sys.exit(0)
assert(args.pctrim<=50)

lines = []
with open(args.filename[0], 'r') as f:
    reader=csv.reader(f, delimiter=args.delim)
    for line in reader:
        lines.append([int(x) for x in line])

columns = max([len(line) for line in lines])


#filtering
data = numpy.array([line for line in lines if len(line) == columns]).transpose()
medians = numpy.median(data,axis=1).tolist()
means = numpy.mean(data,axis=1).tolist()
min_cutoff = numpy.percentile(data, args.pctrim, axis=1)
max_cutoff = numpy.percentile(data, 100-args.pctrim, axis=1)
data = [[val for val in row if min_cutoff[index]<=val<=max_cutoff[index]] for index,row in enumerate(data)]
if args.median:
    filtered_medians = [str(int(numpy.median(row))) for row in data]
    print args.delim.join(filtered_medians)
elif args.findmax:
    filtered_max = [str(int(numpy.max(row))) for row in data]
    print args.delim.join(filtered_max)
else:
    filtered_means = [str(int(numpy.mean(row))) for row in data]
    print args.delim.join(filtered_means)

'''sums = [0]*columns
if args.median:

    medians = [str(int(sorted(l)[(len(l)/2)] if len(l)%2==1 else float(sorted(l)[len(l)/2]+sorted(l)[len(l)/2-1])/2)) for l in zip(*lines)]
    print args.delim.join(medians)

else:

    for line in lines:
        if len(line) == columns:
            processed_rows += 1
            for i in range(columns):
                sums[i]+=int(line[i])

    averages = [str(x/processed_rows) for x in sums]
    print args.delim.join(averages)
'''
