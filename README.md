# Instantly install any npm package as an LWC-ready static resource

The only script you will ever need to use an npm package in LWC. This script faciliates installation, and ease of usage by removing ambiguities around how you would refer to the loaded modules in your LWC.

**Important: The script does not magically make a library locker-service compatible. The library won't work correctly if it is not locker-service compatible.**

## Prerequisites

- Bash shell (with `curl`)
- NodeJS and NPM
- Salesforce CLI

## Usage

Download the script and copy it to your sfdx project root folder. Run `./npmtolwc.sh <list of modules to include in your static resource> <optional flags>`

`./npmtolwc.sh` without any arguments will show you the list of flags and usage instructions.

## Examples

- Running `./npmtolwc.sh d3-scale,d3-time -s time` will create a static resource file named `time` in your project's `staticResources` folder. The name of the library inside the static resource would be `d3scale_d3time`. After importing the resource in your LWC you can use the functions in `d3-scale` with the syntax `d3scale_d3time.d3scale.<function name>`

- Running `./npmtolwc.sh d3-scale,d3-time -s time -l timescale` will create a static resource file named `time` in your project's `staticresources` folder. The name of the library inside the static resource would be `timescale`. After importing the resource in your LWC you can use the functions in `d3-scale` with the syntax `timescale.d3scale.<function name>`

## Features

- A single command to convert any npm package to an LWC-ready static resource.
- Import multiple modules (related or unrelated) into a single static resource file.
- Clear instructions on how to refer to the module(s) in your LWC once loaded.

The script might take a bit longer to run the first time as it downloads `webpack` and other dependencies.
