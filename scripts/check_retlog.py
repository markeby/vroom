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
        self.lines = [line]
        self._is_reg_wr = False
        self._reg_wrs = {}
        self._process_line(line)
        self._complete = False
        self._process_line(line)

    def _process_line(self, line: str) -> None:
        self.lines.append(line)
        (time,cclk,_,*spl) = line.split()

        kvs = dict([kv.split(":") for kv in spl])
        is_reg_wr = kvs.get("reg_wr","0") == "1"
        self._is_reg_wr |= is_reg_wr
        if is_reg_wr:
            self._reg_wrs[int(kvs.get("reg"))] = int(kvs.get("reg_data"),16)
        if (pc := kvs.get("pc",None)) != None:
            self._pc = int(pc,16)

        if kvs.get("eom","1") == "1":
            self._complete = True

    def add_line(self, line: str) -> None:
        self.lines.append(line)
        self._process_line(line)

    def is_complete(self) -> bool:
        return self._complete

    def is_reg_wr(self) -> bool:
        return self._is_reg_wr

    def get_reg_wr_index(self) -> str:
        gprs = [k for k in self._reg_wrs.keys() if k<32]
        if len(gprs) != 1:
            raise("Expecting only one gpr!")
        return gprs[0]

    def get_reg_wr_name(self) -> str:
        return "x" + str(self.get_reg_wr_index())

    def get_reg_wr_data(self) -> int:
        return self._reg_wrs[self.get_reg_wr_index()]

    def pc(self) -> int:
        return self._pc

class SpikeRec(AbstractInstrRec):
    def is_reg_wr(self) -> bool:
        if len(self._lines) < 2:
            return False
        spl = self._lines[1].split()
        if len(spl) < 7:
            return False
        if spl[5][:1] == "x":
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
        if len(recs) > 0 and not recs[-1].is_complete():
            recs[-1].add_line(line)
            print(f"APPEND: {line.strip()}")
        else:
            recs.append(RetlogRec(line=line))
            print(f"NEW:    {line.strip()}")
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

    if (len(spike_recs) != len(retire_recs)):
        croak(f"Wrong number of instructions retired!  expected:{len(spike_recs)} actual:{len(retire_recs)}")

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
