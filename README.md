# sway-build
A 'simple' Makefile to build wlroots, sway and a few other related utilities
# sway-build

The purpose of this repository is to provide 'simple' Makefile to build
wlroots, sway and a few other related utilities.

The Makefile was tested on Debian unstable but its should hopefully work on
other systems with minimal changes.

As of today the Makefile can build the following packages

* [wlroots](https://github.com/swaywm/wlroots) (required by sway)
* [jsonc](https://github.com/json-c/json-c) (required by sway)
* [sway](https://github.com/swaywm/sway)   
* [swayidle](https://github.com/swaywm/swayidle) - Idle management daemon for Sway
* [swaylock](https://github.com/swaywm/swaylock) - Lockscreen application for Sway
* [grim](https://github.com/emersion/grim) - Screenshot application for Sway
* [slurp](https://github.com/emersion/slurp) - Select a region with the mouse (for grim)   
* [mako](https://github.com/emersion/mako) - Notification daemon for Sway

## Required packages

The file debian-packages.txt provides a list of required packages for Debian/Buster (testing).
It is likely incomplete but this is probably a good starting point.

The required `apt-get` command can be obtained with

    make required-apt-install

## Customization of the Makefile

The TARGET variable defines the installation direction and probably needs to
be customized according to your needs.  

Case 1: Installation in /usr/local/

    PREFIX=/usr/local
    LIBDIR=
    SUDO=sudo

Case 2: Installation in a non-standard directory owned by root

    PREFIX=/opt/sway-desktop
    LIBDIR=lib
    SUDO=sudo

Case 3: Installation in a directory owned by user

    PREFIX=$(HOME)/sway/
    LIBDIR=lib
    SUDO=

The variable SUDO is used by the installation targets.

On Debian based systems, LIBDIR forces meson to install
libraires and pkg-config files in the specified subdirectory.
A typical value is `lib` but other values such as `lib32`,
`lib64` or `lib/x86_64-linux-gnu` are possible. That should not 
be needed when installing in `/usr/local`.

## Environment Variables

When using a non-standard target directory, it may be necessary 
to define a few environment varables (PATH, LD_LIBRARY_PATH, PKG_CONFIG_PATH, MANPATH, ...).

Use `make generate-env.sh` to produce a suitable shell script in `$(BUILD_DIR)/env.sh`.

And of course, you need to **source** that generated script before compiling the 
various packages (because of pkg-config) and before starting your sway desktop.

    source  ..../path/to/sway/env.h

## Generic Makefile targets

### make list-targets

List all available targets in the Makefile

### make full-install

Attempt to clone from github, configure, build and install all targets.

### make required-apt-install

Print the command required to install all required packages for Debian/Buster

### make env-sh-build

Generate a shell script to set the required environment variables in $(BUILD_DIR)/env.sh

## Specific Makefile target for package `xxxx`

### make xxxx-git-clone

Clone the sources from git in directory `$SRC_DIR/xxxx/`:

* for most packages, the default behavior is to clone the `master` branch
* `git clone` is made significantly accelerated with the option `--depth=1` but that means that no history is available in the local git repository.

### make xxxx-git-pull

Do a `git pull` in `$SRC_DIR/xxxx/`

### make xxxx-configure

Create the `$(BUILD_DIR)/xxxx` directory and configure. 

### make xxxx-build

Build the package

### make xxxx-clean

Clean a previous build of the package

### make xxx-install

Install the package (only after a successfull build)

### make xxxx-rebuild
An alias for

    make xxxx-clean
    make xxxx-build
 
### make xxxx-all
An alias for

    make xxxx-git-clone
    make xxxx-configure
    make xxxx-clean
    make xxxx-build

### make xxxx-all-install
An alias for

    make xxxx-all
    make xxxx-install


