#!/bin/bash
#
# This installs Python and the pip mirror on the remote server.
#
# The remote server must be capable of building Python.
#

# VERSION: 0.0.1
readonly ThisDir=$(cd $(dirname $0) ; pwd)
set -e
source $ThisDir/utils.sh
source $ThisDir/os.path.sh
source $ThisDir/setup.conf
set +e

[ ! -d $confRemoteInstallPath ] && utils.runx mkdir -p $confRemoteInstallPath || true

# ================================================================
# Package tests.
# ================================================================
utils.info "Installing required packages"
utils.install.pkgs

# ================================================================
# Build Python locally.
# ================================================================
if [ ! -f $confRemoteInstallPath/bin/python ] ; then
    utils.info "Building $confRemoteInstallPath/bin/python"
    utils.runx tar zxf download/$confPythonArchive
    
    utils.runx pushd $confPythonRoot
    ./configure >configure.help
    utils.runx ./configure --prefix=$confRemoteInstallPath
    utils.runx make
    utils.runx make install
    utils.runx popd
else
    utils.info "Already built $confRemoteInstallPath/bin/python"
fi

# ================================================================
# Build setuptools locally.
# ================================================================
if [ ! -d $confSetuptoolsRoot ] ; then
    utils.info "Building $confSetuptoolsRoot"
    utils.runx tar zxf download/$confSetuptoolsArchive
    
    utils.runx pushd $confSetuptoolsRoot
    utils.runx $confRemoteInstallPath/bin/python setup.py --no-user-cfg build
    utils.runx $confRemoteInstallPath/bin/python setup.py install
    utils.runx popd
else
    utils.info "Already built $confSetuptoolsRoot"
fi

# ================================================================
# Build wheel locally.
# ================================================================
if [ ! -d $confWheelRoot ] ; then
    utils.info "Building $confWheelRoot"
    utils.runx tar zxf download/$confWheelArchive
    
    utils.runx pushd $confWheelRoot
    utils.runx $confRemoteInstallPath/bin/python setup.py build
    utils.runx $confRemoteInstallPath/bin/python setup.py install
    utils.runx popd
else
    utils.info "Already built $confWheelRoot"
fi

# ================================================================
# Build pip locally.
# ================================================================
if [ ! -d $confPipRoot ] ; then
    utils.info "Building $confPipRoot"
    utils.runx tar zxf download/$confPipArchive

    utils.runx pushd $confPipRoot
    utils.runx $confRemoteInstallPath/bin/python setup.py build
    utils.runx $confRemoteInstallPath/bin/python setup.py install
    utils.runx popd
else
    utils.info "Already built $confPipRoot"
fi

# ================================================================
# Copy over the pip mirror.
# ================================================================
if [ ! -d $confRemoteInstallPath/pkg ] ; then
    utils.info "Populating the pip mirror: $confRemoteInstallPath/pkg"
    utils.runx rsync -avz pkg/ $confRemoteInstallPath/pkg/
else
    utils.info "Already populated the pip package mirror: $confRemoteInstallPath/pkg"
fi

# ================================================================
# Create pip-remote
# ================================================================
if [ ! -f $confRemoteInstallPath/bin/pip-remote ] ; then
    cat >$confRemoteInstallPath/bin/pip-remote <<EOF
#!/bin/bash

# Don't use readlink, it is not available with -f or -m on Mac OSX.
BinDir=\$(cd \$(dirname \$0) ; pwd)
RootDir=\$(cd \$(dirname \$BinDir) ; pwd)
PkgDir=\$RootDir/pkg
\$BinDir/pip \$* --no-index --find-links=file://\$PkgDir
EOF
    chmod a+x $confRemoteInstallPath/bin/pip-remote
fi

# ================================================================
# Verify the installation.
# ================================================================
utils.info "Verifying the installation"
utils.runx $confRemoteInstallPath/bin/pip-remote list

# ================================================================
# Epilogue.
# ================================================================
cat <<EOF

REMOTE SETUP COMPLETE

You have successfully installed Python $PythonVersion on this system with a
pip package mirror.

The installation is in $confRemoteInstallPath.

To verify the installation try listing the contents of the pip mirror package
and, optionally, installing virtualenv.

   \$ $confRemoteInstallPath/bin/pip-remote list
   \$ $confRemoteInstallPath/bin/pip-remote install virtualenv

EOF

utils.info "Done."
