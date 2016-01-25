#!/bin/bash
#
# Create the remote bundle (remote.tar.bz2). This is the file that is
# transferred to the remote server. It contains everything necessary
# to install Python and the pip mirror.
#
# Works on Mac and Linux (prefer readlink -m but it is not available
# on Mac OSX).

# VERSION: 0.0.1
readonly ThisDir=$(cd $(dirname $0) ; pwd)
set -e
source $ThisDir/utils.sh
source $ThisDir/os.path.sh
source $ThisDir/setup.conf
set +e

# ================================================================
# Main
# ================================================================
Mode='build'
while (( $# )) ; do
    opt="$1"
    shift
    case "$opt" in
        build)
            Mode='build'
            ;;
        clean)
            Mode='clean'
            ;;
        *)
            utils.err "unknown option: '$opt'"
            ;;
    esac
done

# Extra check.
case "$Mode" in
    'build'|'clean')
    ;;
    *)
        utils.err "unknown action '$Mode'"
        ;;

esac

# ================================================================
# Setup
# ================================================================
readonly BuildDir=$ThisDir/bld
readonly RelDir=$ThisDir
readonly PkgDir="$RelDir/pkg"
readonly DownloadDir="$ThisDir/download"
readonly BundleName=remote.tar.bz2
readonly Bundle=$ThisDir/$BundleName

# If gnutar is available on the Mac use it. The BSD version
# of tar generates records that are not recognized by the
# linux version of tar.
readonly Tar=$(which gnutar >/dev/null 2>&1 && echo gnutar || echo tar)

# Directories
readonly Dirs=(DownloadDir BuildDir RelDir)

# ================================================================
#
# Clean
#
# ================================================================
if [[ "$Mode" == 'clean' ]] ; then
    cd $ThisDir
    utils.info "Cleaning in '$(pwd)'."
    
    find . -name '*~' -delete
    
    for DirVar in "${Dirs[@]}" ; do
        Dir="${!DirVar}"
        if [[ "$Dir" != "$ThisDir" ]] ; then
            [ -d $Dir ] && utils.runx rm -rf $Dir || true
        fi
    done

    if [[ "$PkgDir" != "$ThisDir" ]] ; then
        [ -d $PkgDir ] && utils.runx rm -rf $PkgDir || true
    fi

    # Local build/release directories.
    for Dir in bin lib etc include share ; do
        [ -d $Dir ] && utils.runx rm -rf $Dir || true
    done

    # Remove the bundle.
    [ -f $Bundle ] && utils.runx rm -rf $Bundle || true

    utils.info "Cleaned."
    exit 0
fi

# ================================================================
#
# Build
#
# ================================================================
if [[ "$Mode" != 'build' ]] ; then
    utils.err "Unknown mode: $Mode"
fi

# ================================================================
# Create local directories.
# ================================================================
for DirVar in "${Dirs[@]}" ; do
    Dir="${!DirVar}"
    utils.info "$DirVar=$Dir"
    [ ! -d $Dir ] && utils.runx mkdir -p $Dir || true
done

# ================================================================
# Populate the download directory.
# ================================================================
# Use symbolic analysis to figure out what the Archive variable names
# are from setup.conf.
ArchiveVars=(confPythonArchive confSetuptoolsArchive confWheelArchive confPipArchive)
##ArchiveVars=($(set -o posix && set | grep 'Archive=' | awk -F= '{print $1;}'))
for ArchiveVar in ${ArchiveVars[@]} ; do
    ArchiveVal=${!ArchiveVar}
    [[ "$ArchiveVal" == "" ]] && utils.err "variable not set properly: $ArchiveVar" || true
    ArchiveURLVar=$(echo $ArchiveVar | sed -e 's/Archive$/URL/')
    ArchiveURLVal=${!ArchiveURLVar}
    utils.info "$ArchiveVar = $ArchiveVal"
    utils.info "$ArchiveURLVar = $ArchiveURLVal"
    [[ "$ArchiveVal" == "" ]] && err "Variable not set: '$ArchiveVar'." || true
    [[ "$ArchiveURLVal" == "" ]] && err "Variable not set: '$ArchiveURLVar'." || true
    if [ ! -f $DownloadDir/$ArchiveVal ] ; then
        utils.info "Downloading $ArchiveVal from $ArchiveURLVal"
        utils.runx pushd $DownloadDir
        utils.runx wget $ArchiveURLVal
        utils.runx popd
    else
        utils.info "Already downloaded $ArchiveVal from $ArchiveURLVal"
    fi
done

# ================================================================
# Clone out pip2pi.
# ================================================================
if [ ! -d $BuildDir/$confPip2piGitDir ] ; then
    utils.info "Cloning from $confPip2piGitClone"
    utils.runx pushd $BuildDir
    utils.runx git clone $confPip2piGitClone
    utils.runx popd
else
    utils.info "Already cloned from $Pip2piGitClone"
fi

# ================================================================
# Build the components locally.
# ================================================================
utils.info "Installing required packages"
utils.install.pkgs

# Build Python locally.
if [ ! -f $RelDir/bin/python ] ; then
    utils.info "Building $RelDir/bin/python"
    utils.runx pushd $BuildDir
    utils.runx tar zxf $DownloadDir/$confPythonArchive
    
    utils.runx pushd $confPythonRoot
    ./configure >configure.help
    utils.runx ./configure --prefix=$RelDir
    utils.runx make
    utils.runx make install
    utils.runx popd
    
    utils.runx popd
else
    utils.info "Already built $RelDir/bin/python"
fi

# Build setuptools locally.
if [ ! -d $BuildDir/$confSetuptoolsRoot ] ; then
    utils.info "Building $BuildDir/$confSetuptoolsRoot"
    utils.runx pushd $BuildDir
    utils.runx tar zxf $DownloadDir/$confSetuptoolsArchive
    
    utils.runx pushd $confSetuptoolsRoot
    utils.runx $RelDir/bin/python setup.py --no-user-cfg build
    utils.runx $RelDir/bin/python setup.py install
    utils.runx popd
    
    utils.runx popd
else
    utils.info "Already built $BuildDir/$confSetuptoolsRoot"
fi

# Build wheel locally.
if [ ! -d $BuildDir/$confWheelRoot ] ; then
    utils.info "Building $BuildDir/$confWheelRoot"
    utils.runx pushd $BuildDir
    utils.runx tar zxf $DownloadDir/$confWheelArchive
    
    utils.runx pushd $confWheelRoot
    utils.runx $RelDir/bin/python setup.py build
    utils.runx $RelDir/bin/python setup.py install
    utils.runx popd
    
    utils.runx popd
else
    utils.info "Already built $BuildDir/$confWheelRoot"
fi

# Build pip locally.
if [ ! -d $BuildDir/$confPipRoot ] ; then
    utils.info "Building $BuildDir/$confPipRoot"
    utils.runx pushd $BuildDir
    utils.runx tar zxf $DownloadDir/$confPipArchive

    utils.runx pushd $confPipRoot
    utils.runx $RelDir/bin/python setup.py build
    utils.runx $RelDir/bin/python setup.py install
    utils.runx popd
    
    utils.runx popd
else
    utils.info "Already built $BuildDir/$confPipRoot"
fi

# Build pip2pi
if [ ! -f $RelDir/bin/pip2pi ] ; then
    utils.info "Building $RelDir/bin/pip2pi"
    utils.runx pushd $BuildDir/$confPip2piGitDir
    utils.runx $RelDir/bin/python setup.py build
    utils.runx $RelDir/bin/python setup.py install
    utils.runx popd
    [ -d $PkgDir ] && utils.runx rm -rf $PkgDir || true
else
    utils.info "Already built $RelDir/bin/pip2pi"
fi

# ================================================================
# Create the local pip mirror in the $RelDir/pkg using the
# local install.
# ================================================================
if [ ! -d $PkgDir ] ; then
    utils.info "Creating the pip mirror in $PkgDir/"

    # This may not work on some platforms (like Mac OSX).
    # That is okay, it can use the install pip executable
    # instead.
    utils.run $RelDir/bin/pip install pip
    if (( $? )) ; then
        utils.info "This failure is okay. We can use the pip executable instead."
    fi
    
    utils.runx mkdir -p $PkgDir/
    for PipPkg in "${confPipPkgs[@]}" ; do
        utils.runx $RelDir/bin/pip2tgz $PkgDir/ $PipPkg
    done
    utils.runx $RelDir/bin/dir2pi -n $PkgDir/
    [ -f $Bundle ] && utils.runx rm -rf $Bundle || true
else
    utils.info "Already created the pip mirror in $PkgDir/"
fi

# ================================================================
# Bundle up everything for distribution to the remote host.
# ================================================================
if [ ! -f $Bundle ] ; then
    utils.info "Creating the remote bundle: $Bundle"
    PkgDirRel=$(os.path.relpath "$PkgDir")
    DownloadDirRel=$(os.path.relpath "$DownloadDir")
    find . -name '*~' -delete
    TarFiles=( $(find . -type f -maxdepth 1 | sed -e 's@^\./@@' | \
                        grep -v '^#' | \
                        grep -v '^\.' | \
                        grep -v '\.tar' | \
                        grep -v '~$' | \
                        grep -v 'tmp') )
    utils.runx $Tar jcf $Bundle $PkgDirRel $DownloadDirRel "${TarFiles[@]}"
else
    utils.info "Already created the remote bundle: $Bundle"
fi

# ================================================================
# Tell the user what to do next.
# ================================================================
PkgDirRel=$(os.path.relpath "$PkgDir")
cat <<EOF

LOCAL SETUP COMPLETE

The remote bundle $Bundle
has been created that can be built on any linux system.

Copy the remote bundle ($BundleName) to the remote server. You
would normally do that using a USB or portable hard drive but if
you have rsync or scp access you can use that instead. Please
note that if you have network access to the remote server and you
are running the same OS as the remote server, you can simply rsync
this directory structure over.

If you are running a different OS, then you will need to build and
install Python and the pip mirror on the remote host using the
remote bundle that you copied over. That is what is assumed below.

Log into the remote host and extract the archive to a work directory.
Then run the remote.sh command to install it.

You must have a development environment on the remote host that is
capable of building Python.

Here is an example that shows this process. It assumes that scp is
available and that all of the work will be done in
$confRemoteInstallPath/work directory. The work directory will be removed
when the installation is done.

   # Step 1. Copy the bundle bundle to the remote host.
   me@local\$ scp $Bundle me@remote:/tmp/
   me@local\$ ssh -A -Y -t -t me@remote

   # Step 2. Create the work directory
   #         The setup.conf file specifies $confRemoteInstallPath
   #         as the installation path.
   me@remote\$ sudo mkdir -p $confRemoteInstallPath/work
   me@remote\$ cd $confRemoteInstallPath/work
   me@remote\$ cd work

   # Step 3. Extract the contents of the bundle and install
   #         the system using remote.sh.
   #         When the command completes Python and a local pip mirror will
   #         be available in $confRemoteInstallPath/pkg.
   me@remote\$ sudo tar jxf /tmp/$BundleName
   me@remote\$ sudo ./remote.sh
   me@remote\$ cd ..

   # Step 4. Verify that the installation works.
   #         List the local pip mirror contents and then
   #         install virtualenv.
   me@remote\$ sudo $confRemoteInstallPath/bin/pip list --no-index --find-links=file://$confRemoteInstallPath/$PkgDirRel/
   me@remote\$ sudo $confRemoteInstallPath/bin/pip install virtualenv --no-index --find-links=file://$confRemoteInstallPath/$PkgDirRel/

   # Step 5. Clean up - remove the work directory.
   #                    This step is optional.
   me@remote\$ sudo rm -rf $confRemoteInstallPath/work

EOF

utils.info "Done"
