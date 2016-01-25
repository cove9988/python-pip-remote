# python-pip-remote
Install python and a pip mirror on a remote server with no internet access

## Overview
These tools will build Python with a mirrored pip repository on a
remote server with no internet access from a local host with internet
access that is running an OS that is different than the remote OS.

This is useful, for example, if you want to create a Python
installation with a pip mirror on a remote CentOS server from
your Mac Book laptop.

If the local OS and the remote OS are the same, you can simply build
python locally and rsync it over.

The local and remote hosts must have development environments that
include make and C to build Python from source. They must also have
openssl, openssl-devel and krb5-devel packages installed.

## Motivation

This process was developed to help me install Python and a pip on
a remote server with no internet access. The only way that I could
transfer files to the server was with a USB. Fortunately it had a
full development environment.

## How to use the tools

Here is how you use the tools to create a remote installation.

1. Download this package to your local host.
2. Configure the setup by editing setup.conf.
3. Run the `local.sh` script.
4. Copy the `remote.tar.bz2` archive to the remote server.
5. Login to the remote server.
6. Unpack the archive.
7. Run the `remote.sh` script to build, install and verify on the remote server.
8. Verify the installation.
9. Clean up.

Each of the steps is described in more detail in the following
sections.

#### Step 1. Download

   You can download this package by using the following git command
   on your local, internet connected host:
```bash
      me@local$ mkdir -p ~/work/remote-python
      me@local$ cd ~/work/remote-python
      me@local$ git clone https://github.com/jlinoff/python-pip-remote.git
```
   There are two files of interest:

      1. setup.conf  - the configuration file.
      2. local.sh    - the script to run local, internet connected host

#### Step 2. Configuration

   The setup.conf file describes the configuration in detail. Edit it
   to customize your installation.

   For an installation of Python 2.7.11 to /opt/python/2.7.11, you do
   not need to change anything except possibly change the pip packages
   you want in the mirror. See the confPipPkgs list in setup.conf to
   see which pip packages are available by default.

#### Step 3. Create the remote bundle using local.sh

   Run the local.sh script to create the remote bundle that you will use
   to install Python and the pip mirror on the remote server.

   This process includes actually building Python locally to guarantee
   that the correct version is used for creating the pip mirror. This
   process only takes about 10 minutes.

   When it is complete you will have a remote bundle in
   remote.tar.bz2.
   
   The local.sh script requires access to the internet.

#### Step 4. Copy the remote bundle to the remote server.

   Copy the remote bundle (remote.tar.bz2) to the remote server.

   You would normally do that using a USB or portable hard drive but
   if you have rsync or scp access you can use that instead. Please
   note that if you have network access to the remote server and you
   are running the same OS as the remote server, you can simply rsync
   this directory structure over.

   These tools assumes that are running a different OS on the local
   and remote servers.

   This example assumes that you copied the bundle to
   /tmp/remote.tar.bz2 on the remote server.

#### Step 5. Login to the remote server.

   You would typically login as a sudo user.
   For this example I am logging in as root.

#### Step 6. Unpack the archive.

   This example assumes that you copied the bundle to
   /tmp/remote.tar.bz2 on the remote server.
```bash
      root@remote$ mkdir -p ~/work/python
      root@remote$ cd ~/work/python
      root@remote$ tar jxf /tmp/remote.tar.bz2
```
#### Step 7. Run the remote.sh script
   This will build and install Python and pip.
   It will also create the pip-remote script and list the contents
   of the pip mirror.
```bash
      root@remote$ ./remote.sh
```
#### Step 8. Verify the installation

   You verify the installation by listing the contents of the pip
   mirror and, optionally, installing virtualenv.
```bash
      root@remote$ sudo /opt/python/2.7.11/bin/pip-remote list
      root@remote$ sudo /opt/python/2.7.11/bin/pip-remote install
```
#### Step 9. Clean up

   One you have verified that everything works you delete the work
   directory to save disk space.
```bash
      root@remote$ rm -rf ~/work/python
```
## Post Installation
After the installation is complete you can use Python and pip just
like you would on an internet connected system.

## Pre-built remote bundle for Python 2.7.11
There is a pre-built remote bundle for Python 2.7.11 available for you to download
directory if you don't want to run local.sh. It is available here: http://projects.joelinoff.com/python-pip-remote/python-2.7.11-remote.tar.bz2.

The remote bundle file size is about 87MB. The `sum` checksum is `30819 89226`.

Just copy it to your remote system and follow steps 5-9 to build, install
and verify it.

## Acknowledgements
This package relies on the excellent work in pip2pi: https://github.com/wolever/pip2pi and on the folks at Python Software Foundation: https://pypi.python.org/pypi.
