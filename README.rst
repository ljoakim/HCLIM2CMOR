=========================================================================
This is merley an adaptation of the famous CCLM2CMOR tool for the HCLIM model. It rewrites the model data to CORDEX standards. All credits go to the original developers!
=========================================================================

Most of the infomation below is taken from the original text at https://github.com/C2SM-RCM/CCLM2CMOR and posted here with some adaptations.
======

Worldwide coordinated projects for climate data like CMIP and CORDEX demand
that the data meet specific standards very strictly if they are supposed
to be integrated and uploaded to an archive for a world wide distribution
(typically an Earth System Grid Federation node (ESGF) or long term
archives as World Data Centre for Climate (WDCC)). The model output has
to be transformed to meet these specific standards, and this process is
often referred to as CMOR, which stands for Climate Model Output
Rewriting.

In the original project, a CMORization tool has been developped
specifically for the COSMO-CLM (CCLM) model. However, the different
processing steps have been separated in such a way that it was possible
to extend the tool to the HCLIM climate model, resulting in this code repository.

We tried to implement all the details listed in the CORDEX archive specifications, version 3.1.
Please read this document (https://is-enes-data.github.io/cordex_archive_specifications.pdf)
carefully to become familiar with the required standards.

Get the code from GitHub simply by typing ``git clone https://github.com/doblerone/HCLIM2CMOR.git`` 
into your terminal.

Requirements
============
The tool is written for a Unix operating system.
For it to work, a number of command line tools and Python packages are needed.
The command line programs you need are contained in the libraries NCO, netCDF and CDO:
*ncrcat, ncks, ncap2, ncatted (all from NCO), nccopy (from netCDF)* and *cdo*

The program has been tested with the following versions and might not work with older versions:

- NCO: 4.6.8
- netCDF: 4.4.1.1
- CDO: 1.9.0

For the first part of the script (see below) you need ``ksh``. 
For the Python packages please look into the *.py* source code files or
just try to run the code to see which packages are missing.
The code works with Python 2.7 and 3.6 (and maybe also other versions).
The easiest way to get all necessary Python packages is with Miniconda:
Download it (https://conda.io/miniconda.html) and install it on your machine (no root rights necessary).
Installing the package ``netCDF4`` with ``conda install netCDF4`` will then
install all required Python packages.

The tool itself runs without installation.

Sources
=======

Here is a quick overview of the different source code files and
additional files, their location and their purpose. The location is
relative to the source code directory *src*.

=======================================   ==================   ====================================================================================
Filename                                  Location             Purpose
=======================================   ==================   ====================================================================================
**FIRST STEP**
---------------------------------------------------------------------------------------------------------------------------------------------------
master_post.sh                            .                    Job script that executes the first step of the CMORization
settings.sh                               .                    Configuration file for this first step
help                                      .                    Prints helping information on the command line options of *master_post.sh*
mergemon.sh                               hclim_post           Subscript to create the annual files for the second second step. Called by master_post.sh
**SECOND STEP**                                                  
---------------------------------------------------------------------------------------------------------------------------------------------------
master_cmor.sh                            .                    Job script that executes the second step of the CMORization (the Python script)
cmorlight.py                              CMORlight            Main script of the second CMOR step. Calls all other Python functions.
control_cmor.ini                          CMORlight            Configuration file
init_log.py                               CMORlight            Sets up custom logger
get_configuration.py                      CMORlight            Reads in configuration from *control_cmor.ini* and provides functions to read or change the entries
settings.py                               CMORlight            Processes some of the entries in the configuration file and reads in the variables table
tools.py                                  CMORlight            Contains all the functions for processing the files
XXX_variables_table.csv                   CMORlight/Config     Variables table for different models and projects controlling which variables are processed at what time resolution          
coordinates_cordex_eur11.nc               CMORlight/Config     NetCDF file containing e.g. latitude and longitude arrays for domain EUR-11

=======================================   ==================   ====================================================================================


Usage
=====

The CMOR process is divided into two subprocesses which are explained below.

First step
----------
In a first step the model output data is prepared for the actual CMOR process:
Separate yearly time-series files have to be created for each required
variable with the time variable meeting the CORDEX requirements and taking the 
difference between instantaneous and interval representing variables into account.
Additional required fields that are not contained in the model output
have to be calculated. 
For each variable a separate folder (named exactly as the variable) with 
all the data files has to be created in the ``input_CMORlight`` folder.
The file names have to contain the variable name and the time range.
For the variable *pr* and the year 2007 the name would be the following: 

``pr_200701010030-200712312330.nc``

Note that this step is dependent on the regional climate model used. In this project the step is carried out for the **HCLIM43**
model. The scripts referred to in this section are not directly applicable to other models, e.g. CCLM.

For the HCLIM43 model the first step of CMOR can be achieved by calling the
script **master_post.sh**. Before that, adjust the file **settings.sh** to
your needs: Change the name of the driving GCM, the driving
experiment name, the time range for the post-processing and directory paths.
You also need to specify two values in *settings.sh*:

1) **NBOUNDCUT**: The number of boundary lines (latitude and longitude) to be cut off from the data: 

2) **LFILE**: Specify whether to create only primary fields (given out by HCLIM43 directly), only additional fields, or both. This is done by setting **LFILE** to 1, to 2, or to any other number, respectively.

To set **NBOUNDCUT** you can look at the recommended extent of your domain in the CORDEX archive
specifications (https://is-enes-data.github.io/cordex_archive_specifications.pdf).

You can furhter specify whether all available variables are processed (**proc_all=true**) or only specific ones (**proc_list**).
However, the list of variables to process can also be provided on the command line.

The available command line options are displayed with the command
``ksh master_post.sh --help``. The script can either be called with the
shell command ``ksh`` or with the job script command ``sbatch`` (if available on your machine) in the source directory.
If using ``sbatch``, change the name of your account and the location of the log output etc.
in the header of **master_post.sh** or provide them when submitting as command line options, e.g.
``sbatch -J step1_pr_tas_2000 -o $LOGDIR/step1_pr_tas_2000.out -t 01:00:00 master_post.sh -p 'pr tas' -s 2000 -e 2000 -V``
(see also ``sbatch --help``).
Try out first with ``ksh`` to see if the script runs and then use ``sbatch`` to have it most efficient.

The master script calls the subscript **mergemon.sh**. which concatenates
monthly time-series data to annual files with different treatment of
accumulated and instantaneous fields. Additionally, it manipulates
the time variable and creates the additionally requested fields.


Second step
-----------

The actual CMORization takes place in the second step. The Python script
processes each variable at the required/desired time resolutions. It adds the correct 
global attributes, variable attributes and time bounds, creates the correct directory
structure and filenames. It can also derotate wind speed variables and concatenate the
files to chunks depending on time resolution.

Before running the program type ``export IGNORE_ATT_COORDINATES=1``
into your terminal to make the derotation possible or include it in your
terminal configuration file (e.g. .bashrc). If you use the job script 
**master_cmor.sh** (explained  below), you do not need to do this.

The script is run with ``python cmorlight.py [OPTIONS]``. All available
command line options are displayed when using the ``--help`` option and
are repeated here. In most cases there is a short (starting with ``-``) 
and a long option (starting with ``--``):

optional arguments:
  -h, --help            show this help message and exit
  -X EXP, --EXP EXP     Driving experiment (e.g. historical or rcp85)
  -G GCM, --GCM GCM     Driving GCM
  -E ENS, --ENS ENS     Ensemble member of the driving GCM
  -r RESLIST, --resolution RESLIST
                        list of desired output resolutions, comma-separated
                        (supported: 1hr (1-hourly), 3hr (3-hourly),6hr
                        (6-hourly),day (daily),mon (monthly) ,sem
                        (seasonal),fx (for time invariant variables)
  -v VARLIST, --varlist VARLIST
                        comma-separated list of variables (RCM or CORDEX name)
                        to be processed
  -a, --all             process all available variables
  -O, --overwrite       Overwrite existent output files
  -M MULTI, --multi MULTI
                        Use multiprocessing and specify number of available
                        cores.
  -c, --chunk-var       Concatenate files to chunks
  --remove              Remove source files after chunking
  -s PROC_START, --start PROC_START
                        Start year (and start month if not January) for
                        processing. Format: YYYY[MM]
  -e PROC_END, --end PROC_END
                        End year (and end month if not December) for
                        processing. Format: YYYY[MM]
  -P, --propagate       Propagate log to standard output.
  -S, --silent          Write only minimal information to log (variables and
                        resolutions in progress, warnings and errors)
  -V, --verbose         Verbose logging for debugging
  -A, --append_log      Append to log instead of overwrite
  -f, --force_proc      Try to process variable at specific resolution
                        regardless of what is written in the variables table
  -n USE_VERSION, --use-version USE_VERSION
                        version to be added to directory structure
  -i INIFILE, --ini INIFILE
                        configuration file (.ini)
  -d, --no_derotate     no derotation of u and v variables
  -m SIMULATION, --simulation SIMULATION
                        which simulation specific settings to choose


In a file, here called **control_cmor.ini**, processing options, paths and
simulation details are set.  All lists in this file should
be comma-separated and not contain spaces. In the last section
(e.g. named *settings*) of this file you can set simulation specific
options such as global attributes. Note that some command line options can overwrite the settings in this file. Detailed instructions which
variables should be processed with what method at which resolution are
taken from a modified version of the CORDEX variables requirement table
(pdf version here: https://is-enes-data.github.io/CORDEX_variables_requirement_table.pdf).
Here tables for the HCLIM, CCLM, and WRF model are included.
Specify which table to use in the configuration file (**vartable**). For other models you have
to create your own table starting from the tables given here.
Make sure to use the semicolon ";" as delimiter and include a header line.
For a more detailed explanation, see https://github.com/doblerone/HCLIM2CMOR/blob/master/Documentation/Explaining_CSV_table.pdf

If essential variables as *lon* or *lat* are missing in
the data, the script tries to copy them from a file specified under
*coordinates_file* in the configuration file. 
Make sure to provide such a file suitable for your domain and resolution.
Here, files for the domains EUR-11 and ALP-3 are provided.

If you want to process all variables in the table, use the ``--all`` option.
Otherwise, specify the variables with ``--varlist`` (RCM or CORDEX names supported). You can also choose
the resolutions at which to produce the output with ``--resolution`` or
in the variable *reslist* in the configuration file.

You can limit the time range for processing by providing the start and end years on the command line
(``--start``, ``--end``). Otherwise, all available years are processed.
If your data starts in a different month than January in the first year
or ends in a different month than December in the last year, 
you have to add the month to the start or end years to avoid errors.
Currently, seasonal processing only works if either the months 01 to 11 from
the current year and month 12 from the previous year are present or months 03 
to 11 from the current year.

The processing will finish much faster when using multiprocessing
(option ``--multi``). In this way several years are processed simultaneously.
For this, specify the number of available cores after the ``--multi`` command 
and the desired time range over the command line. When multiprocessing, a log file for each year is created. Search
for logged errors or warnings in all these files (e.g. with
``grep WARNING -r`` and ``grep ERROR -r`` in the log directory) to make sure
everything went OK.

After the processing you can concatenate the files to chunks by running
the script again with the ``--chunk-var`` option. Add the option
``--remove`` to this call to delete the superfluent yearly files .

**More optional features**

In the following some more advanced options are described:

-  You can use the job script *master_cmor.sh* to run the job on a
   compute node with ``sbatch master_cmor.sh [OPTIONS]``. Specify your account
   and the location of log output etc. in the master_cmor.sh file or directly on the command line **before** master_cmor.sh.
   You can also pass the options of the python program.

-  If the units attribute of the time variable in your input data is not
   correct, you have to provide the correct time unit in the entry ``alt_units`` 
   in the configuration file and set ``use_alt_units`` to ``True`` there.

-  You can create several configuration
   files and choose the one you want to use with the ``--ini`` option when
   running the main script *cmorlight.py*.
   Within each configuration file you can define several simulation specific sections
   (always named *settings_[EXT]*) and choose one by specifying the
   extension EXT in the configuration file (entry *simulation*) or on the
   command line (option ``--simulation``).

-  The logger has some additional command line options:
   verbose (``--verbose``) and silent (``--silent``) logging, propagation to
   standard output (``--propagate``) and appending to file instead of 
   overwriting (``--append_log``)

-  The entries *global_attr_list* and *global_attr_file* control which global
   attributes should be taken from the configuration file and from your input
   data files, respectively.

-  You can specify the variables to be processed by default and the variables
   to be automatically skipped in the configuration file entries *varlist*
   and *var_skip_list*, respectively.

-  If you want to add vertices to your output files, you have to specify a
   file from which to take them (entry *vertices_file*) and set
   *add_vertices=True* in the configuration file.

-  If you want to output at a resolution even if it is not written in the table
   use the option ``--force_proc`` to force the processing. The output will be created if
   the desired resolution is lower or equal the input file resolution.

-  If you want to put the output in separate folder for testing purposes, 
   change the entry *add_version_to_outpath* in the configuration file to *True*
   . You can provide the version name on the command line (option ``--use_version``). 
   By default the current date is used.

-  If you want to test out the chunking and be able to delete the chunked output 
   easily afterwards, specify a separate folder to put the chunked files into 
   by changing the entry *chunk_into*.

-  The time ranges of the chunked output is set by the entries *AGG_DAY*, 
   *AGG_MON* and *AGG_SEM* for daily, monthly and seasonal resolution, respectively.
   You can change these values, but note the maximum time ranges allowed by CORDEX.

-  NetCDF compression can be switched on or off in the entry *nc_compress*.

-  The option --no_derotate forces no derotation for all variables. For single variables, the derotation can be set in the variable table.

-  By default the input path *DirIn* is extended by the chosen GCM and experiment.
   If you do not want this to happen. Change the entry *extend_DirIn* to 
   *False*.



Quality Assessment
==================

We cannot guarantee that the data processed with this tool perfectly meet
the CORDEX requirements after processing. Please use the Quality Assessment
tool of the DKRZ to check your data. You can find the latest version 
of it here: https://github.com/IS-ENES-Data/QA-DKRZ/
If any errors occur that might have to do with the CMOR tool, don't 
hesitate to contact us. 


Contributing
============

We are happy for everybody who wants to participate in the development 
of the CMOR tool. Look at the open issues to see what there is to do
or create an issue yourself if you found one.

Contact
=======

Currently **THIS** tool (HCLIM43 version) is administrated by Andreas Dobler (MET Norway, andreasd@met.no)

Involved people
===============

In the development of the original tool a number of people from different
institutions were involved:

- Matthias Göbel (Swiss Federal Institute of Technology (ETH), Zürich, Switzerland)
- Hans Ramthun (German Climate Computing Center(DKRZ), Hamburg, Germany)
- Hans-Jürgen Panitz (Karlsruhe Institute of Technology (KIT),Karlsruhe, Germany)
- Klaus Keuler (Brandenburgische Technische Universität Cottbus-Senftenberg (BTU), Cottbus, Germany)
- Christian Steger (Deutscher Wetterdienst (DWD), Offenbach, Germany)

Hans-Jürgen Panitz, Klaus Keuler and Christian
Steger initiated the development of the tool and decided on its
general structure. They also created the table for the Python script for
the CCLM model. Hans Ramthun developed most of the Python code and
Klaus Keuler wrote the script *second.sh*. Matthias Göbel combined the
different scripts to this complete tool, fixed numerous bugs in the
Python code, increased the user-friendliness and flexibility of it and
wrote the first version of this documentation. Silje Sørland,
Daniel Lüthi (both ETH Zürich) and Hans-Jürgen Panitz helped him
with that.

**Thanks to all these people for your work!**




