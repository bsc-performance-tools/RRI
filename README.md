# RRI

## Dependencies

- [lpaggreg library](https://github.com/bsc-performance-tools/lpaggreg). Present as a submodule, located at external/lpaggreg, but must be compiled and installed separately.
- gcc 5
- qt, qt-devel
- qmake
- R

## Related tools

- [folding tool](https://github.com/bsc-performance-tools/folding). Requires version 1.2.1.

## Get the sources

    $ git clone --recursive https://github.com/bsc-performance-tools/RRI.git

## Go into the directory

    $ cd RRI

## Compile and install lpaggreg

    $ cd external/lpaggreg

*Follow README.md instructions*
Once done, go back to RRI root directory

    $ cd ../..

## Configure

*Edit* `options.pri` *to enable or disable the compilation of subsidiary functionalities*.

    $ qmake-qt5

or

    $ qmake-qt4

or

    $ qmake

depending of the version of qt you want to use.

*You may want to change the installation directory, and/or define the lpaggreg library location*

    $ qmake-qt[n] "CONFIG+=GLOBAL_VAR" "PREFIX=[target_location]" "LPAGGREG_PATH=[lpaggreg_location]"

## Compile

    $ make

## Install

    $ make install

## Install R libraries

Missing R libraries can be automatically installed using:

    # sudo make install_R-dependencies


## Apply RRI on a folding directory

    $ rri <folding-directory>

The output is generated by default in `<folding-directory>.rri`.

## Apply RRI on a callerdata file (command line program)

    $ rri -i <folding-directory>/<callerdata.file>

The output is generated by default in `<folding-directory>.rri`.

## Options:

      - -i --inputfile <file>: apply the process on a single callerdata file
      - -h --help: print usage
      - -o --output <directory>: output directory (rri by default)
      - -ts --timeslices [integer]: timeslice number used to discretize the time period (200 by default)
      - -th --threshold [float]: minimal distance between two parameters p (0.0001 by default)
      - -mp --minprop [float]: routine minimal proportion (0.8 by default)
      - -r --region [string]: apply rri on a single region; can be used several times to involve several regions

## Generate graphs from RRI data

    $ rri-visualize <rri-directory>

## Options:

      - -h --help: Print help
      - -c --clean: Remove all the generated pdf
      - -s --size [w] [h]: Set pdf outputs width and height in inch (default: 12 6)
      - -d --dpi [n]: Set pdf outputs dpi (default: 300)
      - -t --threads [n]: Enable multithreading using n threads 

## Generate profiling files

    $ rri-profiling <rri-directory>

## Options:

      - -h --help: Print help
      - -c --clean: Remove all the generated files
      - -d --dpi [n]: Set pdf outputs dpi (default: 300)
      - -f --functions [n]: Limit the number of printed functions in the pdf files to the n functions with the longest duration

