# BP-TAG-VALIDATOR-UPDATER

I'll update the tag value in the `environment_build` JSON file as part of the build process.

## Setup

* Clone the code available at [BP-TAG-VALIDATOR-UPDATER](https://github.com/OT-BUILDPIPER-MARKETPLACE/BP-TAG-VALIDATOR-UPDATER)
* Build the docker image

```sh
git submodule init
git submodule update
docker build -t ot/tag_validator:0.1 .
```

* Do local testing

```sh
docker run -it --rm -v $PWD:/src -e WORKSPACE="path_to_workspace" -e CODEBASE_DIR="codebase_directory" ot/tag_validator:0.1
```

* Debug

```sh
docker run -it --rm -v $PWD:/src -e WORKSPACE="path_to_workspace" -e CODEBASE_DIR="codebase_directory" --entrypoint sh ot/tag_validator:0.1
```

## Script Details

The script performs the following tasks:

1. Sources additional shell functions and logging functions.
2. Defines the codebase location based on environment variables.
3. Waits for a specified duration.
4. Changes directory to the codebase location.
5. Retrieves the current version from the `pom.xml` file.
6. Checks if the current version tag exists in the git repository.
7. If the tag exists, increments the version and updates the `pom.xml` file.
8. Commits the updated `pom.xml` file and tags the repository with the new version.
9. Updates the tag value in the `environment_build` JSON configuration file using `jq` and `sponge`.
10. Prints environment variables used in the script.
11. Performs additional processing and condition checks.

## Environment Variables

- `WORKSPACE`: Path to the workspace directory.
- `CODEBASE_DIR`: Directory name of the codebase.
- `SLEEP_DURATION`: Duration to sleep before proceeding.
- `TASK_STATUS`: Status of the task.
- `ACTIVITY_SUB_TASK_CODE`: Sub-task code for the activity.
- `current_version`: Current version from the `pom.xml` file.
- `new_version`: New version after incrementing the current version.
- `new_tag`: New tag to be updated in the JSON configuration file.
- `json_file`: Path to the `environment_build` JSON file.
- `last_index`: Last index of the version parts.
- `parts`: Parts of the version string.

## Example Usage

To run the script with all required environment variables, use the following command:

```sh
docker run -it --rm -v $PWD:/src -e WORKSPACE="/path/to/workspace" -e CODEBASE_DIR="codebase_directory" ot/tag_validator:0.1
```

To debug the script inside the container, use:

```sh
docker run -it --rm -v $PWD:/src -e WORKSPACE="/path/to/workspace" -e CODEBASE_DIR="codebase_directory" --entrypoint sh ot/tag_validator:0.1
```

This setup ensures that the script will update the tag value directly in the `environment_build` JSON file during the build process.

