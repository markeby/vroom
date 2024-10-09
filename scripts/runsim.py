#!/usr/bin/env python3

"""This is a script.

There are many like it, but this one is mine."""

import argparse
import logging
import sys
import re
import pprint as pp
import typing
import subprocess
import os
import pathlib
from abc import ABC,abstractmethod

logger = logging.getLogger(__name__)
logging.basicConfig(format='%(levelname)s - %(message)s', level=logging.INFO)

def get_git_root(path):
    try:
        result = subprocess.run(['git', '-C', path, 'rev-parse', '--show-toplevel'], capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return None

def find_from_root(rel_path):
    git_root = get_git_root('.')
    final_path = os.path.join(git_root, rel_path)
    if os.path.exists(final_path):
        return final_path
    else:
        raise Exception(f"Could not {final_path}")

def run_sim(vtop, sim_args, fn_run_log):
    command = f"{vtop} {sim_args}"
    with open(fn_run_log, "w") as fh:
        logger.debug("Launching sim...")
        result = subprocess.run(command.split(), stdout=fh)
        logger.debug("Sim done.")
        return result.returncode

def split_log(fn_run_log) -> None:
    logger.debug("Splitting log file...")
    rslt = subprocess.run([find_from_root('scripts/split_log'), "-f", fn_run_log], capture_output=True, text=True, check=True)

def extract_plusarg(sim_args, arg, dflt=None) -> str:
    spl = sim_args.split()
    spl = [x if (":" in x) else f"{x}:1" for x in spl]
    kvs = [x.split(":") for x in spl]
    arg_dict = dict(kvs)
    return arg_dict.get(arg, dflt)

def check_results(sim_args: str) -> bool:
    fn_preload = extract_plusarg(sim_args, "+preload", None)
    if (fn_preload == None):
        logger.warning("Could not find +preload:, skipping checks")
        subprocess.run(["touch", "UNKNOWN"])
        return True
    fn_check = re.sub(r'\.[^\.]*$', '.log', fn_preload)
    if not os.path.exists(fn_check):
        logger.warning(f"Could not find checker file at {fn_check}, skipping checks")
        subprocess.run(["touch", "UNKNOWN"])
        return True
    check_retlog = find_from_root('scripts/check_retlog.py')
    with open("check.log", "w") as fh:
        command = f"{check_retlog} run.RETLOG.log {fn_check}"
        logger.debug("Checking log...")
        result = subprocess.run(command.split(), stdout=fh)
        logger.debug("Done checking.")
        if result.returncode != 0:
            logger.debug("FAIL")
            subprocess.run(["touch", "FAIL"])
            return False
        logger.debug("PASS")
        subprocess.run(["touch", "PASS"])
        return False
    return True

#1516  scripts/check_retlog.py run.RETLOG.log tests/branchy/test.log

def main(args):
    """Main function"""
    logger.info(f"Launching test {args.tag}")

    vtop = None
    if args.vtop != None:
        vtop = args.vtop
    else:
        vtop = find_from_root("obj_dir/Vtop")
    logger.debug(f"Using vtop found in {vtop}")

    # Change to sim dir
    if args.sim_dir != None:
        if not os.path.isdir(args.sim_dir):
            logger.debug(f"Creating directory {args.sim_dir}/")
            os.makedirs(args.sim_dir, exist_ok=True)
        logger.debug(f"Changing to {args.sim_dir}/")
        os.chdir(args.sim_dir)

    # Run the simulation
    run_sim(vtop, args.sim_args, args.run_log)

    # Split the output
    split_log(args.run_log)

    # Check the test
    check_results(args.sim_args)


if __name__=='__main__':
    argparser = argparse.ArgumentParser(description='Convert .dis file to preload file')
    argparser.add_argument('--vtop', '-v', type=str, default=None, help='Path to simulation binary (Vtop)')
    argparser.add_argument('--sim-dir', '-d', type=pathlib.Path, default=None, help='Simulation directory')
    argparser.add_argument('--sim-args', '-s', type=str, help='Simulation arguments')
    argparser.add_argument('--run-log', type=str, default='run.log', help='Path to runlog')
    argparser.add_argument('tag', type=str, help='Test tag')
    argparse_args = argparser.parse_args()
    main(argparse_args)

