#!/bin/bash
#
# Some useful bash utilities.
#

# VERSION: 0.0.1

# ================================================================
# Functions
# ================================================================
function utils.err() {
    local msg="$*"
    local lineno=${BASH_LINENO[0]}
    echo "ERROR:${lineno}: $msg"
    exit 1
}

function utils.info() {
    local msg="$*"
    local lineno=${BASH_LINENO[0]}
    echo "INFO:${lineno}: $msg"
}

# Run a command, do not exit if the comand fails, return the status.
function utils.run() {
    local cmd="$*"
    local lineno=${BASH_LINENO[0]}
    echo "INFO:${lineno}:Cmd: $cmd"
    eval "$cmd"
    local status=$?
    echo "INFO:${lineno}:Status: $status"
    return $status
}

# Run a command, exit if the comand fails.
function utils.runx() {
    local cmd="$*"
    local lineno=${BASH_LINENO[0]}
    echo "INFO:${lineno}:Cmd: $cmd"
    eval "$cmd"
    local status=$?
    if (( $status )) ; then
        echo "INFO:${lineno}:Status: $status"
        utils.err "command failed: $status"
    fi
}

# Install the required packages.
function utils.install.pkgs() {
    local HasYum=$(which yum >/dev/null 2>&1 ; echo $?)
    local HasApt=$(which apt-get >/dev/null 2>&1 ; echo $?)
    local HasPort=$(which port >/dev/null 2>&1 ; echo $?)

    utils.info "HasYum  = $HasYum"
    utils.info "HasApt  = $HasApt"
    utils.info "HasPort = $HasPort"
    
    if (( $HasYum == 0 )) ; then
        # https://github.com/yyuu/pyenv/wiki/Common-build-problems
        local RequiredPackages=(zlib-devel bzip2 bzip2-devel readline-devel ncurses-devel \
                                     sqlite sqlite-devel openssl openssl-devel krb5-devel \
				     libffi-devel)
        utils.runx sudo yum install -y ${RequiredPackages[@]}
    elif (( $HasApt == 0 )) ; then
        # https://github.com/yyuu/pyenv/wiki/Common-build-problems
        local RequiredPackages=(make build-essential libssl-dev zlib1g-dev libbz2-dev \
                               libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev)
        utils.runx sudo apt-get install -y ${RequiredPackages[@]}
    elif (( $HasPort == 0 )) ; then
        utils.runx sudo port install readline
    fi
}

