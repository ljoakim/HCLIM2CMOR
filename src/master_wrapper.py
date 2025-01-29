#!/usr/bin/env python3

import argparse
import datetime
import os
import subprocess
import yaml

import util.vartable_update


CONSTANT_VARIABLES = ["orog", "sftlf", "sftnf", "sfturf", "sftlaf"]
NO_CMOR_VARIABLES = ["clqvi", "mrrod"]  # Should not be cmorized
MERGE_Z_VARIABLES = ["tsl", "mrsol", "mrsfl"]  # Demanding 3D vars


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-f",
        "--file",
        default=None,
        help="File containing the simulation configuration.",
    )
    parser.add_argument(
        "-s",
        "--simulation",
        required=True,
        help="Simulation configuration to run.",
    )
    parser.add_argument(
        "-v",
        "--variables",
        required=True,
        help=(
            "Comma separated list of variables to cmorize."
            " No spaces, e.g. 'tas,tasmin,tasmax'."
        ),
    )
    parser.add_argument(
        "-C",
        "--constant",
        action=argparse.BooleanOptionalAction,
        help=(
            "Cmorize constant (fixed) variables. If this flag is set, only"
            " constant variables in variables list will be cmorized."
        )
    )
    parser.add_argument(
        "-u",
        "--update",
        action=argparse.BooleanOptionalAction,
        help=(
            "Update variables table (fetches cmor tables from github)."
        )
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


def generate_control_cmor(simulation, var_list, simulation_config):
    control_cmor_template_filename = os.path.join(
        os.path.dirname(__file__), "../config/control_cmor_template.ini"
    )
    with open(control_cmor_template_filename) as in_file:
        control_cmor_template = in_file.read()
        format_dict = simulation_config.copy()
        format_dict["simulation"] = simulation
        format_dict["hclim_dir"] = os.environ["HCLIMDIR"]
        format_dict["hclim2cmor_dir"] = os.environ["HCLIM2CMORDIR"]
        format_dict["var_list"] = ",".join(var_list)
        control_cmor = control_cmor_template.format(**format_dict)

    control_cmor_folder = os.path.join(os.path.dirname(__file__), "../control_cmor/")
    if not os.path.exists(control_cmor_folder):
        os.makedirs(control_cmor_folder)
    varstr = "_".join(var_list)
    control_cmor_filename = f"control_cmor_{simulation}_{varstr}.ini"
    control_cmor_path = os.path.join(control_cmor_folder, control_cmor_filename)
    with open(control_cmor_path, "w") as out_file:
        out_file.write(control_cmor)

    return control_cmor_filename


def generate_log_filename(prefix, simulation, start_year, var_list):
    t = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    varstr = "_".join(var_list)
    return f"{prefix}_{simulation}_{start_year}_{varstr}_{t}.out"


def setup_environment(simulation, simulation_config):
    os.environ["OVERRIDE_SIMULATION"] = simulation
    os.environ["OVERRIDE_GCM"] = str(simulation_config["driving_source_id"])
    os.environ["OVERRIDE_EXP"] = str(simulation_config["driving_experiment_id"])
    os.environ["OVERRIDE_NAMETAG"] = str(simulation_config["name_tag"])
    os.environ["OVERRIDE_CONSTANT_FOLDER"] = str(simulation_config["start_year"] - 1)


def run_constants(
    simulation,
    var_list,
    start_year,
    end_year,
    log_dir,
    simulation_config,
    control_cmor,
):
    # Run both post and cmorization for constant variables
    setup_environment(simulation, simulation_config)
    var_list = [var for var in var_list if var in CONSTANT_VARIABLES]
    log_file = generate_log_filename("post_C", simulation, start_year, var_list)
    post_command = (
        f"sbatch -J post_C_{simulation}_{start_year}"
        f" -o {log_dir}/{log_file}"
        f" master_post.sh -C -O"
    )
    post_process = subprocess.run(
        post_command, shell=True, capture_output=True, text=True
    )
    post_job_id = post_process.stdout.strip().split(" ")[-1]
    print(f"Submitted sbatch job (post): {post_job_id}")

    log_file = generate_log_filename("cmor_C", simulation, start_year, var_list)
    cmor_command = (
        f"sbatch -J cmor_{simulation}_{start_year} -n 10"
        f" -d afterok:{post_job_id} -o {log_dir}/{log_file}"
        f" master_cmor.sh -i ../../control_cmor/{control_cmor} -m {simulation}"
        f" -M 10 -v {','.join(var_list)} -s {start_year} -e {end_year}"
        f" -n latest -V -O"
    )
    cmor_process = subprocess.run(
        cmor_command, shell=True, capture_output=True, text=True
    )
    cmor_job_id = cmor_process.stdout.strip().split(" ")[-1]
    print(f"Submitted dependent sbatch job (cmor): {cmor_job_id}")


def run_post(
    simulation,
    var_list,
    start_year,
    end_year,
    log_dir,
    simulation_config,
):
    setup_environment(simulation, simulation_config)
    log_file = generate_log_filename("post", simulation, start_year, var_list)
    if [var for var in var_list if var in MERGE_Z_VARIABLES]:
        timelimstr = "-t 12:00:00"  # increase processing time for 3D vars
    else:
        timelimstr = ""

    post_command = (
        f"sbatch -J post_{simulation}_{start_year} {timelimstr} -o {log_dir}/{log_file}"
        f" master_post.sh -p \'{' '.join(var_list)}\' -s {start_year} -e {end_year} -V -O"
    )
    post_process = subprocess.run(
        post_command, shell=True, capture_output=True, text=True
    )
    job_id = post_process.stdout.strip().split(" ")[-1]
    print(f"Submitted sbatch job (post): {job_id}")
    return job_id


def run_cmor(
    simulation,
    var_list,
    start_year,
    end_year,
    log_dir,
    control_cmor,
    job_deps=None,
):
    log_file = generate_log_filename("cmor", simulation, start_year, var_list)
    deps_string = (
        "-d afterok:" + ":".join([str(j) for j in job_deps])
        if job_deps is not None
        else ""
    )
    cmor_command = (
        f"sbatch -J cmor_{simulation}_{start_year} -n 10"
        f" {deps_string} -o {log_dir}/{log_file}"
        f" master_cmor.sh -i ../../control_cmor/{control_cmor} -m {simulation}"
        f" -M 10 -v {','.join(var_list)} -s {start_year} -e {end_year}"
        f" -n latest -V -O"
    )
    cmor_process = subprocess.run(
        cmor_command, shell=True, capture_output=True, text=True
    )
    job_id = cmor_process.stdout.strip().split(" ")[-1]
    print(f"Submitted dependent sbatch job (cmor): {job_id}")
    return job_id


def run_chunk(
    simulation,
    var_list,
    start_year,
    end_year,
    log_dir,
    control_cmor,
    job_deps=None,
):
    log_file = generate_log_filename("chunk", simulation, start_year, var_list)
    deps_string = (
        "-d afterok:" + ":".join([str(j) for j in job_deps])
        if job_deps is not None
        else ""
    )
    chunk_command = (
        f"sbatch -J chunk_{simulation}_{start_year} -n 10"
        f" {deps_string} -o {log_dir}/{log_file}"
        f" master_cmor.sh -i ../../control_cmor/{control_cmor} -m {simulation}"
        f" -M 10 -v {','.join(var_list)} -s {start_year} -e {end_year}"
        f" -n latest -V -O -c --remove"
    )
    chunk_process = subprocess.run(
        chunk_command, shell=True, capture_output=True, text=True
    )
    job_id = chunk_process.stdout.strip().split(" ")[-1]
    print(f"Submitted dependent sbatch job (chunk): {job_id}")
    return job_id


def main():
    args = parse_args()

    if args.update:
        util.vartable_update.update()

    config = read_simulation_config(args.file)
    log_dir = config["log_dir"]
    simulation_config = config["simulations"][args.simulation]

    var_list = args.variables.split(",")
    control_cmor = generate_control_cmor(
        args.simulation, var_list, simulation_config
    )

    start_year = simulation_config["start_year"]
    end_year = simulation_config["end_year"]

    if args.constant:
        print("Running post process and cmorization on constant fields...")
        run_constants(
            args.simulation,
            var_list,
            start_year,
            end_year,
            log_dir,
            simulation_config,
            control_cmor,
        )
    else:
        total_time_range = end_year - start_year
        time_step = 10
        parallel_job_count = total_time_range // time_step + 1

        # Submit all post jobs and get their job ids
        post_job_ids = []
        for t in range(parallel_job_count):
            post_job_ids.append(
                run_post(
                    args.simulation,
                    var_list,
                    start_year + t * time_step,
                    min(end_year, start_year + (t + 1) * time_step - 1),
                    log_dir,
                    simulation_config,
                )
            )

        # Submit all cmor jobs, collect their job ids,
        # and add post job ids as dependencies
        cmor_job_ids = []
        cmor_var_list = [var for var in var_list if var not in NO_CMOR_VARIABLES]
        for t in range(parallel_job_count):
            cmor_job_ids.append(
                run_cmor(
                    args.simulation,
                    cmor_var_list,
                    start_year + t * time_step,
                    min(end_year, start_year + (t + 1) * time_step - 1),
                    log_dir,
                    control_cmor,
                    job_deps=post_job_ids,
                )
            )

        # Finally, submit chunk job, with cmor job ids as dependencies
        run_chunk(
            args.simulation,
            cmor_var_list,
            start_year,
            end_year,
            log_dir,
            control_cmor,
            job_deps=cmor_job_ids,
        )

    print("All jobs submitted.")


if __name__ == "__main__":
    print("HCLIM2CMOR wrapper.")
    main()
