import argparse
import datetime
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
            "Comma separated list of variables to CMORize."
            " No spaces, e.g. 'tas,tasmin,tasmax'."
        ),
    )
    parser.add_argument(
        "-C",
        "--create_const",
        action=argparse.BooleanOptionalAction,
        help="CMORize constant variables.",
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
        format_dict["var_list"] = var_list
        control_cmor = control_cmor_template.format(**format_dict)

    control_cmor_folder = os.path.join(os.path.dirname(__file__), "../control_cmor/")
    if not os.path.exists(control_cmor_folder):
        os.makedirs(control_cmor_folder)
    varstr = "_".join(var_list.split(","))
    control_cmor_filename = f"control_cmor_{simulation}_{varstr}.ini"
    control_cmor_path = os.path.join(control_cmor_folder, control_cmor_filename)
    with open(control_cmor_path, "w") as out_file:
        out_file.write(control_cmor)

    return control_cmor_filename


def generate_log_filename(prefix, simulation, start_year, var_list):
    t = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    varstr = "_".join(var_list.split(","))
    return f"{prefix}_{simulation}_{start_year}_{varstr}_{t}.out"


def run_constants(
    simulation, var_list, start_year, end_year, log_dir, simulation_config, control_cmor
):
    # Runs both post and cmorization for constant variables
    #

    os.environ["OVERRIDE_SIMULATION"] = simulation
    os.environ["OVERRIDE_GCM"] = str(simulation_config["driving_source_id"])
    os.environ["OVERRIDE_EXP"] = str(simulation_config["driving_experiment_id"])
    os.environ["OVERRIDE_NAMETAG"] = str(simulation_config["name_tag"])
    os.environ["OVERRIDE_CONSTANT_FOLDER"] = str(simulation_config["start_year"] - 1)

    fixed_vars = ["orog", "sftlf", "sftnf", "sfturf", "sftlaf"]
    var_list = ",".join(
        [
            var
            for var in var_list.split(",")
            if var in fixed_vars
        ]
    )

    log_file = generate_log_filename("post_C", simulation, start_year, var_list)
    post_command = (
        f"sbatch -J post_C_{simulation}_{start_year} -W"
        f" -o {log_dir}/{log_file}"
        f" master_post.sh -C"
    )
    post_process = subprocess.run(post_command, shell=True)
    post_process.check_returncode()

    log_file = generate_log_filename("cmor_C", simulation, start_year, var_list)
    cmor_command = (
        f"sbatch -J cmor_{simulation}_{start_year} -n 10 -W"
        f" -o {log_dir}/{log_file}"
        f" master_cmor.sh -i ../../control_cmor/{control_cmor} -m {simulation}"
        f" -M 10 -v {var_list} -s {start_year} -e {end_year}"
        f" -n latest -V"
    )
    cmor_process = subprocess.run(cmor_command, shell=True)
    cmor_process.check_returncode()


def run_post(
    simulation, var_list, start_year, end_year, log_dir, simulation_config, control_cmor
):
    os.environ["OVERRIDE_SIMULATION"] = simulation
    os.environ["OVERRIDE_GCM"] = str(simulation_config["driving_source_id"])
    os.environ["OVERRIDE_EXP"] = str(simulation_config["driving_experiment_id"])
    os.environ["OVERRIDE_NAMETAG"] = str(simulation_config["name_tag"])
    os.environ["OVERRIDE_CONSTANT_FOLDER"] = str(simulation_config["start_year"] - 1)
    log_file = generate_log_filename("post", simulation, start_year, var_list)
    spaced_var_list = " ".join(var_list.split(","))
    test_list=['tsl','mrsol','mrsfl']
    if [ele for ele in test_list if(ele in spaced_var_list)]:
       timelimstr = '-t 12:00:00' #increase processing time for 3D vars
    else:
       timelimstr = ''
    post_command = (
        f"sbatch -J post_{simulation}_{start_year} -W {timelimstr}"
        f" -o {log_dir}/{log_file}"
        f" master_post.sh -p '{spaced_var_list}' -s {start_year} -e {end_year} -V"
    )
    post_process = subprocess.run(post_command, shell=True)
    post_process.check_returncode()


def run_cmor(
    simulation, var_list, start_year, end_year, log_dir, simulation_config, control_cmor
):
    log_file = generate_log_filename("cmor", simulation, start_year, var_list)
    cmor_command = (
        f"sbatch -J cmor_{simulation}_{start_year} -n 10 -W"
        f" -o {log_dir}/{log_file}"
        f" master_cmor.sh -i ../../control_cmor/{control_cmor} -m {simulation}"
        f" -M 10 -v {var_list} -s {start_year} -e {end_year}"
        f" -n latest -V"
    )
    cmor_process = subprocess.run(cmor_command, shell=True)
    cmor_process.check_returncode()


def run_chunk(
    simulation, var_list, start_year, end_year, log_dir, simulation_config, control_cmor
):
    log_file = generate_log_filename("chunk", simulation, start_year, var_list)
    chunk_command = (
        f"sbatch -J chunk_{simulation}_{start_year} -n 10 -W"
        f" -o {log_dir}/{log_file}"
        f" master_cmor.sh -i ../../control_cmor/{control_cmor} -m {simulation}"
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

    control_cmor = generate_control_cmor(args.simulation, args.variables, simulation_config)

    start_year = simulation_config["start_year"]
    end_year = simulation_config["end_year"]
    total_time_range = end_year - start_year
    time_step = 10
    parallel_processes_per_step = total_time_range // time_step + 1

    post_process_args = [
        (
            args.simulation,
            args.variables,
            start_year + t * time_step,
            min(end_year, start_year + (t + 1) * time_step - 1),
            log_dir,
            simulation_config,
            control_cmor,
        )
        for t in range(parallel_processes_per_step)
    ]

    if args.create_const:
        start_time = time.time()
        print("Running post process and cmorization on constant fields...")
        run_constants(
            args.simulation,
            args.variables,
            start_year,
            end_year,
            log_dir,
            simulation_config,
            control_cmor,
        )
        step1_time = time.time()
        print(
            f"Post process and cmorization of constant fields"
            f" took {step1_time - start_time} seconds."
        )

    else:
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
        run_chunk(
            args.simulation,
            args.variables,
            start_year,
            end_year,
            log_dir,
            simulation_config,
            control_cmor,
        )
        step3_time = time.time()
        print(f"Chunking took {step3_time - step2_time} seconds.")

    print("Done.")
