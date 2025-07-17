#!/opt/homebrew/bin/python3.12

import sys
import os

input_file = sys.argv[1]
in_wo_path = input_file.split('/')[-1]
in_wo_path_file, in_wo_path_suffix = in_wo_path.rsplit('.', 1)
output_file = in_wo_path_file + ".hex"

def bin_to_mem(infile, outfile):
    binfile = open(infile, 'rb')
    binfile_content = binfile.read(os.path.getsize(infile))
    datafile = open(outfile, 'w')

    index = 0
    b0 = 0
    b1 = 0
    b2 = 0
    b3 = 0

    for b in  binfile_content:
        if index == 0:
            b0 = b
            index = index + 1
        elif index == 1:
            b1 = b
            index = index + 1
        elif index == 2:
            b2 = b
            index = index + 1
        elif index == 3:
            b3 = b
            index = 0
            array = []
            array.append(b3)
            array.append(b2)
            array.append(b1)
            array.append(b0)
            datafile.write(bytearray(array).hex() + '\n')

    binfile.close()
    datafile.close()


if __name__ == '__main__':
    if len(sys.argv) == 2:
        bin_to_mem(input_file, output_file)
    else:
        print('Usage: %s binfile datafile' % sys.argv[0], sys.argv[1])
