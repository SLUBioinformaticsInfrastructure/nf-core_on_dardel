# nf-core_on_dardel
How to run nf-core pipelines on PDC/Dardel, with useful scripts

## copy files

Copy the files into a new directory on Dardel. This will be the directory you will run the analyses from. 

The files you will need are: 

- pixi.toml
- runscript.sh
- params.yml

## install pixi

With Pixi we will create the environment to run the nf-core pipeline. Check out their documentation [here](https://pixi.sh/latest/). 

Logged into Dardel, you can install Pixi using the following command: 

```{.bash}
curl -fsSL https://pixi.sh/install.sh | sh
```

### about pixi.toml

The Pixi file, pixi.toml, we are using here specifies the environment we need to run the nf-core pipeline. 

<details>
  <summary>More information on the file</summary>
The toml is Pixi's project configuration file. 

The first section, `[project]`, such as authorized sources of packages, the environment name and the platform the environment is running in. 

The second section, `[tasks]`, contains a task called `nf-core` that can be executed with Pixi. The command is to run the bash script called `runscript.sh`.

The third secion, `[dependencies]`, specifies the software we want to have available in the environment. Instead of the asterics one can also specify version numbers. 

More information [here](https://prefix.dev/docs/pixi/configuration).   

</details>


## adapt the runscript

You need to substitute `path_to_project_directory`on line 75 with the path to the directory on Dardel where you want files to be stored. 

If you want to run a nf-core pipeline that is not nf-core/mag, you need to change to the appropriate pipeline in lines 44 and 45. 

If you want to change the default location of the working directory or the output directory, change lines 28 and 29, respectively. 

Change permissions on the runscript: 

```{.bash}
chmod +x runscript.sh
```


<details>
  <summary>More information on the file</summary>
	
The runscript is running the pipeline for you, and also does some automated maintenance in the background.

`set -euo pipefail` tells bash to fail your script at certain errors, to give you more information and avoid issues down the line. More information [here](https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425?permalink_comment_id=3935570).

The next function determines if you are working on Dardel (or Rackham, but that's not important here). This will come in handy later. 

The second function is running the nf-core pipeline. The command for that is the `nextflow run nf-core/XX` etc. Beforehand it sets a number of variables for you. Unless you want to change the location of the work directory and the result directory you do not have to change anything there. 

After the actual run command, still in the same function, the script will clean up the cache for you, delete empty directories, and change permissions so all members of the same project have access to the generated files.

The last bit of the script is printing out the name of the cluster the pipeline is being run on, and then calls the `run_nextflow` function with the appropriate settings. Here you need to set the path to your project directory.   

</details>

## adapt the parameter file, params.yml

Here you need to substitute `compute_project` with the ID of your compute project, e.g. naiss2024-XX-YYY. 

And you can add all the other parameters for the pipeline, in `yml`format. If you have used the nf-core launchpad and got a json file you can user a json to yml converter or your choice. 

Paths to databases can be absolute, or relative to the directory you run the pipeline out of. The database location on Dardel is `/pdc/software/resources/blastdb/`.

## add your input file

Check your pipeline, in case of nf-core/mag you'll need a samplesheet.csv. 

## start screen session (optional)

```{.bash}
screen -S nf_core
```

More session commands [here](https://www.geeksforgeeks.org/screen-command-in-linux-with-examples/).

## run pipeline

Run the pipeline with:

```{.bash}
pixi run nf-core
```

Here, `nf-core` is the name of the task in the `pixi.toml`file. `pixi run` tells Pixi to execute the task. 

## bonus: increase resources for certain processes

Add another file `nextflow.config`, this one will be automatically detected by nextflow and it's contents applied. It will override the other directives given to the pipeline. 

This will implement a general error strategy, where the process will be retried up to three times if the error exit status indicated a resource problem (exit status between 137 and 140). 

Change the process name, and fill in appropriate values for the runtime, number of cpu's and requested memory (or bettter, just choose the one that is problematic and do not change the other options):


```{.bash}
process {
	errorStrategy =  { task.exitStatus in 137..140 ? 'retry' : 'terminate' }
    maxRetries = 3

	withName:'PROCESS_NAME'{
		time   = { task.attempt > 1 ? task.previousTrace.time * 2 : (2.h) }
		cpus   = { task.attempt > 1 ? task.previousTrace.cpus * 2 : (16) }
		memory = { task.attempt > 1 ? task.previousTrace.memory * 2 : (90.GB) }
	}

}
```



