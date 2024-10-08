#!/usr/bin/env python3

"""This is a script.

There are many like it, but this one is mine."""

import argparse
import logging
import sys
import re
import pprint as pp
import typing

logger = logging.getLogger(__name__)
logging.basicConfig(format='%(levelname)s - %(message)s', level=logging.INFO)

from abc import ABC,abstractmethod

class AbstractInstrRec(ABC):
    def __repr__(self):
        return f"l:{self.label} p:{hex(self.pc())}"

    def __init__(self, lines: typing.Optional[[str]] = None, label: str = None):
        if lines == None:
            lines = []
        lines = [s.strip() for s in lines]
        self._lines = lines
        self.label = label

    def append(self, line: str) -> None:
        self._lines.append(line.strip())

    def text(self) -> str:
        return "\n".join(self._lines)

    @abstractmethod
    def is_reg_wr(self) -> bool:
        return False

    @abstractmethod
    def get_reg_wr_name(self) -> str:
        return "x0"

    @abstractmethod
    def get_reg_wr_data(self) -> int:
        return 0

    @abstractmethod
    def pc(self) -> int:
        return 0

class RetlogRec(AbstractInstrRec):
    def __init__(self, line: str):
        super().__init__(lines=[line], label=None)
        (time,cclk,_,*spl) = line.split()
        #pp.pprint(spl)
        self.kvs = dict([kv.split(":") for kv in spl])

    def is_reg_wr(self) -> bool:
        is_reg_wr = self.kvs.get("reg_wr","0")
        return int(is_reg_wr) > 0

    def get_reg_wr_name(self) -> str:
        return "x" + self.kvs.get("reg")

    def get_reg_wr_data(self) -> int:
        return int(self.kvs.get("reg_data"),16)

    def pc(self) -> int:
        return int(self.kvs.get("pc"),16)

class SpikeRec(AbstractInstrRec):
    def is_reg_wr(self) -> bool:
        if len(self._lines) < 2:
            return False
        spl = self._lines[1].split()[-2:]
        if spl[0][:1] == "x":
            return True
        return False

    #core   0: 3 0x0000000000001000 (0x00000297) x5  0x0000000000001000
    def get_reg_wr_name(self) -> str:
        return self._lines[1].split()[5]

    def get_reg_wr_data(self) -> int:
        return int(self._lines[1].split()[6],16)

    def pc(self) -> int:
        return int(self._lines[0].split()[2],16)

def read_spike_log(spikelog):
    recs = []
    label = None
    for line in spikelog:
        (core,hart,*spl) = line.split()
        if spl[0][0] == ">":
            label = spl[1]
        else:
            if spl[0][:2] == "0x":
                recs.append(SpikeRec(label=label, lines=[line]))
                label = None
            else:
                recs[-1].append(line)
    return recs

def read_retire_log(retlog):
    recs = []
    label = None
    for line in retlog:
        recs.append(RetlogRec(line=line))
    return recs

def croak(msg: str) -> None:
    print(msg)
    exit(-1)

def main(args):
    """Main function"""
    spike_recs = read_spike_log(args.fn_spikelog)
    retire_recs = read_retire_log(args.fn_retlog)

    ### Skip spike_recs to _start
    spike_recs = spike_recs[5:]

    pairs = zip(spike_recs, retire_recs)
    for (s,r) in pairs:
        print("----")
        print(s.text())
        if (s.pc() != r.pc()):
            print(r.text())
            croak(f"PC mismatch! expected:{hex(s.pc())} actual:{hex(r.pc())}")
        if s.is_reg_wr() != r.is_reg_wr():
            print(r.text())
            if (s.is_reg_wr()):
                croak(f"Reg write expected but not seen!")
            else:
                croak(f"Unexpected reg write seen")
        if s.is_reg_wr():
            if (s.get_reg_wr_name() != r.get_reg_wr_name()):
                croak(f"Reg destination mismatch!  expected:{s.get_reg_wr_name()} actual:{r.get_reg_wr_name()}")
            if (s.get_reg_wr_data() != r.get_reg_wr_data()):
                croak(f"Reg data mismatch!  expected:{hex(s.get_reg_wr_data())} actual:{hex(r.get_reg_wr_data())}")

    # lines = []
    # for line in args.fn_dis:
    #     if m := re.match(r'^\s+([0-9A-Fa-f]+):\t([0-9A-Fa-f]+)\s+[a-z]', line):
    #         addr,val = m.groups()
    #         lines.append(f"{addr} {val}")
    # args.fn_out.write('\n'.join(lines) + '\n')

if __name__=='__main__':
    argparser = argparse.ArgumentParser(description='Convert .dis file to preload file')
    argparser.add_argument('fn_retlog', type=argparse.FileType('r'), help='Retire log (e.g. run.RETLOG.log)')
    argparser.add_argument('fn_spikelog', type=argparse.FileType('r'), help='Spike commit log (e.g. test.log)')
    argparse_args = argparser.parse_args()
    main(argparse_args)
