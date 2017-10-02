Phil's `~/etc/vagrant`
======================

This repository started as “let's put common system setup scripts I create
into `~/etc/vagrant/` and then refer to them from `Vagrantfile` I have
elsewhere, copying them into the local repo as-and-when if needed”.

I then added a `stub/` sub-directory, intended to just hold a fast list of
boxes in the `Vagrantfile` and bringing them up "simply", referencing the
setup scripts if need be.  I wanted one place to refer to all the boxes I
might reasonably care about, to populate `vagrant box list` and be able to
bring up any one of those boxes as a near-empty image.

I hit issues with one OS's official RelEng images being Rather Defective and
added lots of workarounds, via tunable attributes on the object defining the
machine we want to bring up.

Then there was a call for testing snapshots of OpenSSH, coming up to a new
release, and I decided to use what I had lying around.  I repeatedly automated
things until it was just `all.sh` to test on each of a bunch of machines and
pull back the configure/make report to a local directory.


## Top Directory

Scripts suitable for referencing as a script provisioner from a `Vagrantfile`.

`pt` is Pennock Tech, LLC, my company.  `ptlocal.foo.sh` references some tag
`foo` which might be matched by some box.  The stub uses this for an `ostype`
such as `debian-family`.

This is intended primarily for my use, so my own apt repo is automatically
configured.  The setup assumes that I have an apt repo for a particular
distribution/release pairing, so some caution might be needed if extending the
list of D/R for which Vagrant images are wanted.


## `simpler/`

If you're not familiar with Vagrant but can program, start here; it's not the
simplest Vagrantfile (empty, or about three lines) but shows the core of
what's in `stub/` in a reduced way.

We define a Ruby class to hold our per-machine data; a list of instances of
that class, then we reference the Vagrant object to define a node for each
instance in the list.  We set a couple of environment variables and reference
a provisioning script, if it exists.

```
vagrant help
vagrant status
vagrant up centos-7
vagrant ssh centos-7
#...
vagrant destroy centos-7
```

That should be enough to get started with understanding what's going on with
Vagrant and the general style of what we're doing in `stub/`.  Stub has just
... "grown" a lot.  From something which started out very much like
`simpler/`.

If you change provisioning scripts when a machine is already up, use the
`provision` sub-command to re-run them.


## `stub/`

An organically-grown `Vagrantfile` which shows what you can do when your DSL
is Ruby.  This has good and bad sides.

This `Vagrantfile` assumes that it is in `~/etc/vagrant/stub`.  (Well, it
assumes that `~/etc/vagrant` is useful as a starting point, anyway).

Some common shell/editor files I use get copied in, if their parent dir
exists.  If you are not me, then they're not likely to.

If `PT_BUILD_ASSETS` is found in environ, then it's a whitespace-separated
list of paths to files which should be copied into `/tmp/` of the VM.

If `PT_BUILD_SCRIPTS` is found in environ, then it's a whitespace-separated
list of paths relative to `~/etc/vagrant`, which should be used as
provisioning scripts at the end of everything else.

Note that some attempt is made to have the downloaded packages area of the
guest VM be mapped to a cache area in the host OS, so that repeatedly bringing
up the same OS will avoid needing to re-download everything.  This will be a
directory called `Vagrant/` within one of a few places: `~/Library/Caches/` on
macOS, `$XDG_CACHE_HOME` `~/.cache/` if it exists, else a Vagrant environment
area, _probably_ `~/.vagrant.d/cache`.

In addition, if `http_proxy` is a current environment variable when you invoke
Vagrant, then the value will be propagated into the guest.

If you have a command in your path called `not_at_home` and it returns false,
then you might experience breakage as the install scripts for apt-based
systems try to configure an HTTP proxy of `http://cheddar.lan:3142`, which is
specific to my environment.  For me, that's an `apt-cacher-ng` instance.


## openssh

To build all expected OSes, edit `Version.sh` to be the snapshot date-stamp,
then invoke `./all.sh` from within that directory.  The list of images which
will be tested by default is within that `all.sh` script, as defaults for when
no names are passed on argv.  Each machine will be brought up, OpenSSH
installed and tested, the output of the configure/make-test copied back to a
local logs dir, and the machine _suspended_, not destroyed.

When done, you can bring out of suspension any machines of interest, or
destroy them all.

Arranging NFS syncing for some OSes will require sudo for Vagrant to auto-edit
`/etc/exports`.  <https://www.vagrantup.com/docs/synced-folders/nfs.html> has
instructions on how to make this passwordless.

I use the `publish-reports` script to copy the files to where I make them
publicly available.  It probably won't work for you and is not part of
`all.sh`.
