import argparse
import os
import subprocess
import time
import yaml
from multiprocessing import Pool


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-f",
        "--file",
        default=None,
        help="file containing the simulation configuration",
    )
    parser.add_argument(
        "-s",
        "--simulation",
        default=None,
        help="simulation configuration to run",
    )
    return parser.parse_args()


def read_simulation_config(config_file_path):
    if config_file_path is None:
        config_file_path = os.path.join(
            os.path.dirname(__file__), "../config/simulation_config.yml"
        )
    with open(config_file_path) as config_file:
        config = yaml.safe_load(config_file)
    return config


def run_post(simulation, start_year, end_year, log_dir, simulation_config):
    os.environ["OVERRIDE_SIMULATION"] = simulation
    os.environ["OVERRIDE_GCM"] = str(simulation_config["gcm_name"])
    os.environ["OVERRIDE_EXP"] = str(simulation_config["experiment"])
    os.environ["OVERRIDE_NAMETAG"] = str(simulation_config["name_tag"])
    var_list = str(simulation_config["var_list"])
    post_command = (
        f"sbatch -J post_{simulation}_{start_year} -W"
        f" -o {log_dir}/post_{simulation}_{start_year}.out"
        f" master_post.sh -p '{var_list}' -s {start_year} -e {end_year} -V"
    )
    post_process = subprocess.run(post_command, shell=True)
    post_process.check_returncode()


def run_cmor(simulation, start_year, end_year, log_dir, simulation_config):
    var_list = ",".join(str(simulation_config["var_list"]).split())
    cmor_command = (
        f"sbatch -J cmor_{simulation}_{start_year} -n 10 -t 04:00:00 -W"
        f" -o {log_dir}/cmor_{simulation}_{start_year}.out"
        f" master_cmor.sh -i ../../config/control_cmor.ini -m {simulation}"
        f" -M 10 -v {var_list} -s {start_year} -e {end_year}"
        f" -n latest -V"
    )
    cmor_process = subprocess.run(cmor_command, shell=True)
    cmor_process.check_returncode()


def run_chunk(simulation, start_year, end_year, log_dir, simulation_config):
    var_list = ",".join(str(simulation_config["var_list"]).split())
    chunk_command = (
        f"sbatch -J chunk_{simulation}_{start_year} -n 10 -t 04:00:00 -W"
        f" -o {log_dir}/chunk_{simulation}_{start_year}.out"
        f" master_cmor.sh -i ../../config/control_cmor.ini -m {simulation}"
        f" -M 10 -v {var_list} -s {start_year} -e {end_year}"
        f" -n latest -V -c --remove"
    )
    chunk_process = subprocess.run(chunk_command, shell=True)
    chunk_process.check_returncode()


if __name__ == "__main__":
    print("HCLIM2CMOR wrapper.")

    args = parse_args()
    config = read_simulation_config(args.file)
    log_dir = config["log_dir"]
    simulation_config = config["simulations"][args.simulation]

    start_year = simulation_config["start_year"]
    end_year = simulation_config["end_year"]
    total_time_range = end_year - start_year

    time_step = 10
    parallel_processes_per_step = total_time_range // time_step + 1

    post_process_args = [
        (
            args.simulation,
            start_year + t * time_step,
            min(end_year, start_year + (t + 1) * time_step - 1),
            log_dir,
            simulation_config,
        )
        for t in range(parallel_processes_per_step)
    ]

    # Parallel sbatch post and cmor.
    # Note: if program is stopped during run, the sbatch
    # jobs will not be automatically stopped. Use the
    # squeue/scancel to view and stop sbatch jobs.
    #
    start_time = time.time()
    with Pool(parallel_processes_per_step) as p:
        print("Running post process...")
        p.starmap(run_post, post_process_args)
        step1_time = time.time()
        print(f"Post process took {step1_time - start_time} seconds.")

        print("Running cmorization...")
        p.starmap(run_cmor, post_process_args)
        step2_time = time.time()
        print(f"CMORization took {step2_time - step1_time} seconds.")

    # Chunking could also be done in parallel, but care
    # must be taken to parallelize over time ranges that
    # work with chunking rules.
    #
    print("Chunking...")
    run_chunk(args.simulation, start_year, end_year, log_dir, simulation_config)
    step3_time = time.time()
    print(f"Chunking took {step3_time - step2_time} seconds.")

    print("Done.")
