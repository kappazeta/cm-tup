# cm-tup

Scripts to create CVAT or Segments.AI tasks from a directory of tiles.

## Setup for CVAT and segments.ai

1. Clone the CVAT repository if you don't have it yet.

        git clone https://github.com/kappazeta/cvat.git

2. Enter the directory of the `cm-tup` repository.

3. Create a conda environment for the CVAT CLI utility.

        conda env create -f environment.yml

## Configuration

The script expects an S2 product directory which has been subtiled and converted, using `cm-vsm` (<https://github.com/kappazeta/cm-vsm.git>).

In the `cm-vsm` output directory, `cm-tup` expects to find a configuration file `cvat-tup.cfg` and a label classes definition file `classes.json`. In the case that these files don't exist yet, `cm-tup` creates them from templates.

An example `cvat-tup.cfg` file:

```
cvat_host_addr=localhost
cvat_host_port=8080
cvat_credentials=YOUR_CVAT_USERNAME:YOUR_CVAT_PASSWORD
cvat_cli_path=/YOUR_PATH_TO_CVAT_WORKING_COPY/utils/cli/cli.py
git_repository=https://github.com/kappazeta/cvat_cloudmask_annotations.git
```

Here, `YOUR_PATH_TO_CVAT_WORKING_COPY`, `YOUR_CVAT_USERNAME` and `YOUR_CVAT_PASSWORD` ought to be replaced with values which correspond to your setup.

An example `classes.json` file:

```
[
    {   
        "name": "CLEAR",
        "attributes": []
    },  
    {   
        "name": "CLOUD_SHADOW",
        "attributes": []
    },  
    {   
        "name": "CLOUD",
        "attributes": []
    },  
    {   
        "name": "SEMI_TRANSPARENT_CLOUD",
        "attributes": []
    }   
]
```

##  Running

1. Activate the conda environment

        source activate cvat-cli

2. Run the script with the output directory of `cm-vsm` as the only argument. Note that the path should end with the suffix `.CVAT`.

        ./bin/cvat-tup.sh YOUR_PATH

## Segments.ai configuration and running

1. First, you need to have an user account on https://segments.ai
2. Under `bin` directory, segments-ai-uploader.py is used to upload tiles in your dataset.
It should be configured in the following way:

- `#unique_client_id` should be replaced with a newly generated API key from your segments.ai user profile;
 
- `#dataset_name` should be replaced with a full dataset name (e.g. your_user_name/playground);

- `#path_to_directory_with_subtiles` should be replaced with a full path to a directory with subtiles. By default the script expects the folder to be a collection of products with tiles inside (e.g. target_directory/product_name/tile_x_y.png). To change the nesting level and search for tiles right inside the specified directory `/**/*.png` can be changed to `/*.png`, where * is a wildcard character.
 
3. When the configuration is done, run the script by typing `python segments-ai-uploader.py` under `cvat-cli` conda environment.
 
