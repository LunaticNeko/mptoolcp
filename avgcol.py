'''
Average all columns from a CSV.
'''

import argparse
import csv

parser = argparse.ArgumentParser(description="Averages columns from a CSV-like file")
parser.add_argument('filename', type=str, nargs=1)
parser.add_argument('--delim', type=str, default='\t')

args = parser.parse_args()

lines = []
with open(args.filename[0], 'r') as f:
    reader=csv.reader(f, delimiter=args.delim)
    for line in reader:
        lines.append(line)

rows = len(lines)
columns = max([len(line) for line in lines])
sums = [0]*columns

for line in lines:
    for i in range(columns):
        sums[i]+=int(line[i])

averages = [str(x/rows) for x in sums]
print args.delim.join(averages)
