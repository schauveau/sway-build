
THIS_MAKEFILE=$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))


#
# PREFIX is the absolute path to the installation directory.
#
# The SUDO command will is only used during installation
#
# When set to a non-empty value, LIBDIR forces libraires
# and pkg-config files to be installed in the specified
# subdirectory.
# A typical value is 'lib' but other values such as 'lib32',
# 'lib64' or 'lib/x86_64-linux-gnu' may be used.
# 

#PREFIX=/usr/local
#LIBDIR=
#SUDO=sudo

PREFIX=$(HOME)/opt/sway/
LIBDIR=lib
SUDO=


#
# Absolute paths to the sources and build directories.
# 
SRC_DIR=$(abspath ./src)
BUILD_DIR=$(abspath ./build)

#
# Where to find git
#
GIT=git

#
# MODE controls the optimization level for packages built
# with meson. See below for the possible values.
# 
MODE=release

ifeq ($(MODE),none)
 MESON_OPTIM_FLAGS=""
 CFLAGS=
else ifeq ($(MODE),debug)
 MESON_OPTIM_FLAGS=--optimization g
 CFLAGS=-g
else ifeq ($(MODE),release)
 MESON_OPTIM_FLAGS=--optimization 3
 CFLAGS=-O3
else
  $(error ERROR: Unsupported value MODE="$(MODE)")
endif

#
#
#

MESON=meson
MESON_SETUP=$(MESON) setup --prefix=$(PREFIX) -Dwerror=false $(MESON_OPTIM_FLAGS)


# Number of parallel jobs while building the tools
JOBS=4

# Define VERB=0 or VERB=1 to hide or show the compilation commands
VERB=1

#
# 
#
NINJA=ninja
NINJA_INSTALL=$(SUDO) ninja

#
# SUBMAKE is the make command used to build and link
# the actual packages (when not using ninja).
# 
# By resetting MAKEFLAGS we insure that the
# options passed to this top-level makefile are
# properly ignored.
#
SUBMAKE=make MAKEFLAGS= 
SUBMAKE_INSTALL=$(SUDO) make MAKEFLAGS= 

#
# It can occasionally be convenient to keep multiple build
# directories (e.g. debug vs release).
# This variable specifies a suffix that can be added to
# the build directory
#
BUILD_SUFFIX=


############################################################
#
# A few variables that you probably do not need to change
#
#############################################################

ifeq ($(VERB),0) 
else ifeq ($(VERB),1)
  NINJA_VERB=-v
else
  $(error ERROR: Unsupported value VERB="$(VERB)" -- Expect "0" or "1")
endif

ifdef LIBDIR
  MESON_SETUP+=--libdir=$(LIBDIR)
  CONFIGURE_LIBDIR=--libdir=$(PREFIX)/$(LIBDIR)
endif

######################################################
#
# Primary targets
#
######################################################

all: list-targets

list-targets:
	@echo Possible targets are
	@grep '^[-[:alnum:]]*:' $(THIS_MAKEFILE) | sed -e 's/:.*//' -e 's/^/  /'

full-install:
	$(MAKE) wlroots-all-install
	$(MAKE) jsonc-all-install
	$(MAKE) sway-all-install
	$(MAKE) swayidle-all-install
	$(MAKE) swaylock-all-install
	$(MAKE) grim-all-install
	$(MAKE) slurp-all-install
	$(MAKE) mako-all-install 

required-apt-install:
	@echo apt-get install $(shell sed 's/ *#.*//' debian-packages.txt)


######################################################
#
# Create a shell script with the required environment
# variables. 
#
# That should not be needed when PREFIX=/usr/local
#
######################################################

$(BUILD_DIR)/env.sh:	
	./generate-env.sh $(PREFIX) > $(BUILD_DIR)/tmp_env.sh
	mv $(BUILD_DIR)/tmp_env.sh $(BUILD_DIR)/env.sh
	rm -f $(BUILD_DIR)/tmp_env.sh
	@echo "#"
	@echo "#  Environment file generated in $(BUILD_DIR)/env.sh"
	@echo "#  Please do"
	@echo "#"
	@echo "#     source $(BUILD_DIR)/env.sh"
	@echo "#"

env-sh-build: $(BUILD_DIR)/env.sh


##################################################################
#
# wlroots
#
##################################################################

WLROOTS_GIT="https://github.com/swaywm/wlroots"
WLROOTS_SRC=$(SRC_DIR)/wlroots
WLROOTS_BUILD=$(BUILD_DIR)/wlroots$(BUILD_SUFFIX)
WLROOTS_FLAGS=

.PHONY: wlroots-git-clone  wlroots-git-pull wlroots-configure  wlroots-build 
.PHONY: wlroots-clean wlroots-rebuild wlroots-all  wlroots-install wlroots-all-install

$(WLROOTS_SRC)/meson.build:
	$(GIT) clone --depth=1 -b master $(WLROOTS_GIT)  $(WLROOTS_SRC)

$(WLROOTS_BUILD)/build.ninja:
	$(MESON_SETUP) $(WLROOTS_FLAGS) "$(WLROOTS_SRC)" "$(WLROOTS_BUILD)"

wlroots-git-clone: $(WLROOTS_SRC)/meson.build

wlroots-git-pull:
	$(GIT) pull -C $(WLROOTS_SRC) pull

wlroots-configure: $(WLROOTS_BUILD)/build.ninja

wlroots-build: $(WLROOTS_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(WLROOTS_BUILD)" -j $(JOBS)

wlroots-clean: $(WLROOTS_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(WLROOTS_BUILD)" clean

wlroots-rebuild:
	$(MAKE) wlroots-clean
	$(MAKE) wlroots-build

wlroots-all:
	$(MAKE) wlroots-git-clone
	$(MAKE) wlroots-configure
	$(MAKE) wlroots-build

wlroots-install: 
	$(NINJA_INSTALL) $(NINJA_VERB) -C "$(WLROOTS_BUILD)" install

wlroots-all-install:	
	$(MAKE) wlroots-all
	$(MAKE) wlroots-install


##################################################################
#
# json-c
#
#  Running the autogen.sh script in the source directory
#  should not be required but the default configure specifically
#  requires automake 1.14 that is not available on my system. 
#
##################################################################

JSONC_GIT="https://github.com/json-c/json-c"
JSONC_SRC=$(SRC_DIR)/jsonc
JSONC_BUILD=$(BUILD_DIR)/jsonc$(BUILD_SUFFIX)
JSONC_FLAGS=

.PHONY: jsonc-configure jsonc-build jsonc-clean jsonc-rebuild jsonc-install  

$(JSONC_SRC)/autogen.sh:
	$(GIT) clone --depth=1 -b json-c-0.13 $(JSONC_GIT) $(JSONC_SRC)

$(JSONC_BUILD)/Makefile:
	command -v aclocal-1.14 || $(MAKE) jsonc-src-autogen
	mkdir "$(JSONC_BUILD)"
	cd "$(JSONC_BUILD)" && $(JSONC_SRC)/configure $(CONFIGURE_LIBDIR) --prefix=$(PREFIX) CFLAGS="$(CFLAGS)"

jsonc-git-clone: $(JSONC_SRC)/autogen.sh

jsonc-git-pull:
	$(GIT) pull -C $(JSONC_SRC) pull

jsonc-src-autogen:
	cd "$(JSONC_SRC)" && sh autogen.sh

jsonc-configure: $(JSONC_BUILD)/Makefile

jsonc-build: $(JSONC_BUILD)/Makefile
	$(SUBMAKE) -C $(JSONC_BUILD) V=$(VERB)

jsonc-clean: $(JSONC_BUILD)/Makefile
	$(SUBMAKE) -C $(JSONC_BUILD) clean

jsonc-install: 
	$(SUBMAKE_INSTALL) -C $(JSONC_BUILD) install

jsonc-rebuild:
	$(MAKE) jsonc-clean
	$(MAKE) jsonc-build

jsonc-all:
	$(MAKE) jsonc-git-clone
	$(MAKE) jsonc-configure
	$(MAKE) jsonc-build

jsonc-all-install:	
	$(MAKE) jsonc-all
	$(MAKE) jsonc-install


##################################################################
#
# Sway
#
##################################################################

SWAY_GIT="https://github.com/swaywm/sway"
SWAY_SRC=$(SRC_DIR)/sway
SWAY_BUILD=$(BUILD_DIR)/sway$(BUILD_SUFFIX)
SWAY_FLAGS=

.PHONY: sway-git-clone  sway-git-pull sway-configure  sway-build 
.PHONY: sway-clean sway-rebuild sway-all  sway-install sway-all-install

$(SWAY_SRC)/meson.build:
	$(GIT) clone --depth=1 -b master $(SWAY_GIT) $(SWAY_SRC)

$(SWAY_BUILD)/build.ninja:
	$(MESON_SETUP) $(SWAY_FLAGS) "$(SWAY_SRC)" "$(SWAY_BUILD)"

sway-git-clone: $(SWAY_SRC)/meson.build

sway-git-pull:
	$(GIT) pull -C $(SWAY_SRC) pull

sway-configure: $(SWAY_BUILD)/build.ninja

sway-build: $(SWAY_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(SWAY_BUILD)" -j $(JOBS)

sway-clean: $(SWAY_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(SWAY_BUILD)" clean

sway-rebuild:
	$(MAKE) sway-clean
	$(MAKE) sway-build

sway-all:
	$(MAKE) sway-git-clone
	$(MAKE) sway-configure
	$(MAKE) sway-build

sway-install: 
	$(NINJA_INSTALL) $(NINJA_VERB) -C "$(SWAY_BUILD)" install

sway-all-install:	
	$(MAKE) sway-all
	$(MAKE) sway-install


##################################################################
#
# Swayidle: This is sway's idle management daemon
#
##################################################################

SWAYIDLE_GIT="https://github.com/swaywm/swayidle"
SWAYIDLE_SRC=$(SRC_DIR)/swayidle
SWAYIDLE_BUILD=$(BUILD_DIR)/swayidle$(BUILD_SUFFIX)
SWAYIDLE_FLAGS=

.PHONY: swayidle-git-clone  swayidle-git-pull swayidle-configure  swayidle-build 
.PHONY: swayidle-clean swayidle-rebuild swayidle-all  swayidle-install swayidle-all-install

$(SWAYIDLE_SRC)/meson.build:
	$(GIT) clone --depth=1 -b master $(SWAYIDLE_GIT) $(SWAYIDLE_SRC)

$(SWAYIDLE_BUILD)/build.ninja:
	$(MESON_SETUP) $(SWAYIDLE_FLAGS) "$(SWAYIDLE_SRC)" "$(SWAYIDLE_BUILD)"

swayidle-git-clone: $(SWAYIDLE_SRC)/meson.build

swayidle-git-pull:
	$(GIT) pull -C $(SWAYIDLE_SRC) pull

swayidle-configure: $(SWAYIDLE_BUILD)/build.ninja

swayidle-build: $(SWAYIDLE_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(SWAYIDLE_BUILD)" -j $(JOBS)

swayidle-clean: $(SWAYIDLE_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(SWAYIDLE_BUILD)" clean

swayidle-rebuild:
	$(MAKE) swayidle-clean
	$(MAKE) swayidle-build

swayidle-all:
	$(MAKE) swayidle-git-clone
	$(MAKE) swayidle-configure
	$(MAKE) swayidle-build

swayidle-install: 
	$(NINJA_INSTALL) $(NINJA_VERB) -C "$(SWAYIDLE_BUILD)" install

swayidle-all-install:	
	$(MAKE) swayidle-all
	$(MAKE) swayidle-install


##################################################################
#
# Swaylock: A lockscreen application for Sway
#
##################################################################

SWAYLOCK_GIT="https://github.com/swaywm/swaylock"
SWAYLOCK_SRC=$(SRC_DIR)/swaylock
SWAYLOCK_BUILD=$(BUILD_DIR)/swaylock$(BUILD_SUFFIX)
SWAYLOCK_FLAGS=

.PHONY: swaylock-git-clone  swaylock-git-pull swaylock-configure  swaylock-build 
.PHONY: swaylock-clean swaylock-rebuild swaylock-all  swaylock-install swaylock-all-install

$(SWAYLOCK_SRC)/meson.build:
	$(GIT) clone --depth=1 -b master $(SWAYLOCK_GIT) $(SWAYLOCK_SRC)

$(SWAYLOCK_BUILD)/build.ninja:
	$(MESON_SETUP) $(SWAYLOCK_FLAGS) "$(SWAYLOCK_SRC)" "$(SWAYLOCK_BUILD)"

swaylock-git-clone: $(SWAYLOCK_SRC)/meson.build

swaylock-git-pull:
	$(GIT) pull -C $(SWAYLOCK_SRC) pull

swaylock-configure: $(SWAYLOCK_BUILD)/build.ninja

swaylock-build: $(SWAYLOCK_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(SWAYLOCK_BUILD)" -j $(JOBS)

swaylock-clean: $(SWAYLOCK_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(SWAYLOCK_BUILD)" clean

swaylock-rebuild:
	$(MAKE) swaylock-clean
	$(MAKE) swaylock-build

swaylock-all:
	$(MAKE) swaylock-git-clone
	$(MAKE) swaylock-configure
	$(MAKE) swaylock-build

swaylock-install: 
	$(NINJA_INSTALL) $(NINJA_VERB) -C "$(SWAYLOCK_BUILD)" install

swaylock-all-install:	
	$(MAKE) swaylock-all
	$(MAKE) swaylock-install


##################################################################
#
# Grim: A screenshot application for sway/wlroot
#
##################################################################

GRIM_GIT="https://github.com/emersion/grim.git"
GRIM_SRC=$(SRC_DIR)/grim
GRIM_BUILD=$(BUILD_DIR)/grim$(BUILD_SUFFIX)
GRIM_FLAGS=

.PHONY: grim-git-clone  grim-git-pull grim-configure  grim-build 
.PHONY: grim-clean grim-rebuild grim-all  grim-install grim-all-install

$(GRIM_SRC)/meson.build:
	$(GIT) clone --depth=1 -b master $(GRIM_GIT) $(GRIM_SRC)

$(GRIM_BUILD)/build.ninja:
	$(MESON_SETUP) $(GRIM_FLAGS) "$(GRIM_SRC)" "$(GRIM_BUILD)"

grim-git-clone: $(GRIM_SRC)/meson.build

grim-git-pull:
	$(GIT) pull -C $(GRIM_SRC) pull

grim-configure: $(GRIM_BUILD)/build.ninja

grim-build: $(GRIM_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(GRIM_BUILD)" -j $(JOBS)

grim-clean: $(GRIM_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(GRIM_BUILD)" clean

grim-rebuild:
	$(MAKE) grim-clean
	$(MAKE) grim-build

grim-all:
	$(MAKE) grim-git-clone
	$(MAKE) grim-configure
	$(MAKE) grim-build

grim-install: 
	$(NINJA_INSTALL) $(NINJA_VERB) -C "$(GRIM_BUILD)" install

grim-all-install:	
	$(MAKE) grim-all
	$(MAKE) grim-install

##################################################################
#
# Slurp: Select a region using the mouse
#
##################################################################

SLURP_GIT="https://github.com/emersion/slurp"
SLURP_SRC=$(SRC_DIR)/slurp
SLURP_BUILD=$(BUILD_DIR)/slurp$(BUILD_SUFFIX)
SLURP_FLAGS=

.PHONY: slurp-git-clone  slurp-git-pull slurp-configure  slurp-build 
.PHONY: slurp-clean slurp-rebuild slurp-all  slurp-install slurp-all-install

$(SLURP_SRC)/meson.build:
	$(GIT) clone --depth=1 -b master $(SLURP_GIT) $(SLURP_SRC)

$(SLURP_BUILD)/build.ninja:
	$(MESON_SETUP) $(SLURP_FLAGS) "$(SLURP_SRC)" "$(SLURP_BUILD)"

slurp-git-clone: $(SLURP_SRC)/meson.build

slurp-git-pull:
	$(GIT) pull -C $(SLURP_SRC) pull

slurp-configure: $(SLURP_BUILD)/build.ninja

slurp-build: $(SLURP_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(SLURP_BUILD)" -j $(JOBS)

slurp-clean: $(SLURP_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(SLURP_BUILD)" clean

slurp-rebuild:
	$(MAKE) slurp-clean
	$(MAKE) slurp-build

slurp-all:
	$(MAKE) slurp-git-clone
	$(MAKE) slurp-configure
	$(MAKE) slurp-build

slurp-install: 
	$(NINJA_INSTALL) $(NINJA_VERB) -C "$(SLURP_BUILD)" install

slurp-all-install:	
	$(MAKE) slurp-all
	$(MAKE) slurp-install


##################################################################
#
# Mako: Notification daemon for Sway
#
##################################################################

MAKO_GIT="https://github.com/emersion/mako"
MAKO_SRC=$(SRC_DIR)/mako
MAKO_BUILD=$(BUILD_DIR)/mako$(BUILD_SUFFIX)
MAKO_FLAGS=

.PHONY: mako-git-clone  mako-git-pull mako-configure  mako-build 
.PHONY: mako-clean mako-rebuild mako-all  mako-install mako-all-install

$(MAKO_SRC)/meson.build:
	$(GIT) clone --depth=1 -b master $(MAKO_GIT) $(MAKO_SRC)

$(MAKO_BUILD)/build.ninja:
	$(MESON_SETUP) $(MAKO_FLAGS) "$(MAKO_SRC)" "$(MAKO_BUILD)"

mako-git-clone: $(MAKO_SRC)/meson.build

mako-git-pull:
	$(GIT) pull -C $(MAKO_SRC) pull

mako-configure: $(MAKO_BUILD)/build.ninja

mako-build: $(MAKO_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(MAKO_BUILD)" -j $(JOBS)

mako-clean: $(MAKO_BUILD)/build.ninja
	$(NINJA) $(NINJA_VERB) -C "$(MAKO_BUILD)" clean

mako-rebuild:
	$(MAKE) mako-clean
	$(MAKE) mako-build

mako-all:
	$(MAKE) mako-git-clone
	$(MAKE) mako-configure
	$(MAKE) mako-build

mako-install: 
	$(NINJA_INSTALL) $(NINJA_VERB) -C "$(MAKO_BUILD)" install

mako-all-install:	
	$(MAKE) mako-all
	$(MAKE) mako-install

