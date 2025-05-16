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
    test text   

</details>


## adapt the runscript

You need to substitute `path_to_project_directory`on line 58 with the path to the directory on Dardel where you want files to be stored. 

If you want to run a nf-core pipeline that is not nf-core/mag, you need to change to the appropriate pipeline in lines 33 and 34. 

If you want to change the default location of the working directory or the output directory, change lines 20 and 21, respectively. 

<details>
  <summary>More information on the file</summary>
    test text   

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

## bonus: increase resources for certain processes

Add another file `nextflow.config`.

```{.bash}
process {
	withName:'KRAKEN2'{
		time   = 2.h
		cpus   = 16
		memory =  90.GB
	}

}
```



