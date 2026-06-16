#!/usr/bin/env python3

import subprocess
import sys

def WI310(address):
    proc = subprocess.Popen(f"upower -i $(upower -e | grep {address})", stdout=subprocess.PIPE, shell=True)
    output = proc.stdout.read().decode('utf-8')
    split_lines = output.split("\n")
    percentage = [x for x in split_lines if "percentage" in x]
    if percentage:
        percentage = percentage[0]
        print(f"{percentage.replace('percentage:', '').strip()}")
    else:
        print("Not Connected")

    return output


def main():
    address = sys.argv[1]
    WI310(address)



if __name__ == "__main__":
    main()
