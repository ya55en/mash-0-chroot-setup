# Ma'shmallow-0 test environment framework

A setup framework for environments where `mash` can be tested under
different condition. Docker would be a better choice, however, we couldn't
get `.AppImage` executables work there, hence chroot environment.


## What is this based on

Environments built are Debian/Ubuntu based. The base system is installed
via [deboostrap][1] and other levels (e.g. desktop environment) are
built within the live chroot, using [apt][2].


## How it works

### Prerequisites

You need the following in order to use this framework:

  - deboostrap
  - make
  - rsync
  - an `.env` file based on `.env.sample`

For the last item, simply do:

```
$ cd ./chroot-setup
$ cp .env.sample .env
```

(Otherwise `make` would yell something like:

```
Makefile:8: .env: No such file or directory
make: *** No rule to make target '.env'.  Stop.
```
)

-----

You shouldn't need to alter the values there, but take a look and feel
free to adjust something, if neceesary (and if you know what you are
doing.)


### Tarball creation phase

First, a tarball is created for each test environment (once). As mentioned,
this is done using `debootstrap` and `apt`. Main scripts used for this
phase:

- `./4make/build-tarball.sh`, which at certain stage invokes environment-
  specific scripts from `./4make/inside-chroot/`.

- local `Makefile` recipes are used to drive the whole thing. (These
  are most interesting when a chroot is to be brought up -- see next
  section.)

- others (less prominent) can be found in `./4make/`;


### Bringing up a chroot environment

At time of chroot environment activation, a ramdisk mount is created (large
enough to hold the environment AND the packages and application to be
installed during the tests), then the environment-specific tarball is
un-archived into the ramdisk directory. Then the current `mash` code from
`.src` is packed and put into the chroot, together whith `src/install.sh`.
Finally, all necessary mounts are done and the chroot can be activated and
used further.

Typically, the local `Makefile` targets are used to bring an environment
AND meanwhile, create the corresponding tarball if it is not yet created:

- `make status` will tell if a chroot is active and what it is (e.g.
  headless or mate-desktop).
- `make headless-up` would, if necessary, first build the headless env
  tarball; then use that to set up a headless chroot environment.
- `make headless-down` shuts that environment down (if it is up).
- `make mate-desktop-up` would, if necessary, first build a stripped version
   of the mate dekstop environment into a tarball, then use that to set up
   a mate desktop enabled chroot environment.
- `make mate-desktop-down` shuts that environment down (if it is up).


## Known issues

No known issues.

(We have moved to a non-incremental `tar` archives, so the issue with the
error message during un-archiving is no longer there.)


## TODO

Lots of things, to be populated later. Most importantly:

- Convert the `chroot-setup` directpry into a submodule within it's own
  git repository hosted on github.

- Experiment with xz compression.

- Create releases for the `chroot-setup` project with the two archived
  chroot environments.

- Have test execution targets directly into the `Makefile` and use these
  to run e2e and other tests;


[1]: <https://wiki.debian.org/Debootstrap> "Debootstrap"

[2]: <https://wiki.debian.org/Apt> "Debian apt"

[3]: <https://www.gnu.org/software/tar/manual/html_node/Incremental-Dumps.html> "TAR, incremental"
