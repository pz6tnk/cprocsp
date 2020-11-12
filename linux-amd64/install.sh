#!/bin/sh

# Copyright(C) 2005-2017
#
# Этот файл содержит информацию, являющуюся
# собственностью компании Крипто-Про.
#
# Любая часть этого файла не может быть скопирована,
# исправлена, переведена на другие языки,
# локализована или модифицирована любым способом,
# откомпилирована, передана по сети с или на
# любую компьютерную систему без предварительного
# заключения соглашения с компанией Крипто-Про.
#
# This is proprietary information of
# Crypto-Pro company.
#
# Any part of this file can not be copied,
# corrected, translated into other languages,
# localized or modified by any means,
# compiled, transferred over a network from or to
# any computer system without preliminary
# agreement with Crypto-Pro company

# IMPORTANT NOTE
# echo's to stdout are redirected to gui-notifications,
# so don't change output stream if not necessary.

COMPAT_VERSION="1.0.0-1"
VERSION="4.0.*-5"
PACKAGE_NAMES=""
FROM_REPO=0

# Exit codes.
SUCCESS=0
FAILURE=1
PACKAGES_NOT_AVAILABLE=2

parse_args() {
    _enclosure="kc1"
    while ! [ -z "$1" ] ; do
        case "$1" in
            "kc1")
                ;;
            "kc2")
                _enclosure="kc2"
                ;;
            "--from-repo")
                FROM_REPO=1
                ;;
            "-help"|"--help")
                show_help
                exit "${SUCCESS}"
                ;;
            *)
                _additional_packages="$*"
                break
                ;;
        esac
        shift
    done
    PACKAGE_NAMES="lsb-cprocsp-base \
lsb-cprocsp-rdr lsb-cprocsp-${_enclosure} lsb-cprocsp-capilite cprocsp-curl \
lsb-cprocsp-ca-certs \
${_additional_packages}"
}

show_help() {
    echo "\
usage: ./install.sh [kc1|kc2] [package [...]]
  kc1: install kc1 packages (by default)
  kc2: install kc2 packages
  [package [...]]: list of additional packages"
}

which_architecture() {
    machine_architecture="$(uname -m)"
    case "${machine_architecture}" in
        "x86_64"|"amd64"|"ppc64"|"ppc64le")
            bits_postfix="-64"
            ;;
        *)
            bits_postfix=""
            ;;
    esac
    case "${machine_architecture}" in
        arm*)
            is_arm=1
            ;;
        *)
            is_arm=0
            ;;
    esac
}

check_if_debian_system() {
    if [ -f /etc/debian_version ] ||
        grep Ubuntu /etc/lsb-release > /dev/null 2>&1
    then
        is_debian_system=1
    else
        is_debian_system=0
    fi
}

check_release_attributes() {
    if ls ./lsb-cprocsp-base*.deb > /dev/null 2>&1 ; then
        is_debian_release=1
    else
        is_debian_release=0
    fi
    if ls ./lsb-cprocsp-base*.rpm > /dev/null 2>&1 ; then
        is_rpm_release=1
    else
        is_rpm_release=0
    fi
    if ls ./lsb-cprocsp-rdr-64* > /dev/null 2>&1 ; then
        is_64_release=1
    else
        is_64_release=0
    fi
}

# Use dpkg or alien on debian systems, otherwise use rpm.
set_inst_cmd() {
    if [ "${is_debian_system}" -eq 1 ] ; then
        if [ "${is_debian_release}" -eq 1 ] ; then
            inst_cmd="dpkg -i"
        else
            inst_cmd="alien -kci"
        fi
    else
        if [ "${is_rpm_release}" -eq 1 ] ; then
            inst_cmd="rpm -i"
        else
            echo "Error: you are trying to install debian packages on not debian package system"
            exit "${FAILURE}"
        fi
    fi
}

# The release variables are used to construct full names of packages.
set_release_variables() {
    if [ "${is_debian_system}" -eq 1 ] &&
        [ "${is_debian_release}" -eq 1 ]
    then
        first_delimeter="_"
        noarch="all"
        second_delimeter="_"
        extension=".deb"
    else
        first_delimeter="-"
        noarch="noarch"
        second_delimeter="."
        extension=".rpm"
    fi
    case "${machine_architecture}" in
        # Enforce to install 64-bit packages on 64-bit system.
        "x86_64"|"amd64")
            if [ "${is_debian_system}" -eq 1 ] &&
                [ "${is_debian_release}" -eq 1 ]
            then
                arch="amd64"
            else
                arch="x86_64"
            fi
            ;;
        "ppc64"|"ppc64le")
            arch="${machine_architecture}"
            ;;
        arm*|"mips")
            arch="${noarch}"
            ;;
        *)
            if [ "${is_debian_system}" -eq 1 ] &&
                [ "${is_debian_release}" -eq 1 ]
            then
                arch="i386"
            elif ls ./*.i686.rpm > /dev/null 2>&1 ; then
                arch="i686"
            else
                arch="i486"
            fi
            ;;
    esac
}

lsb_warning() {
    echo "Warning: lsb-core or lsb-compat package not installed - installing cprocsp-compat-debian.
If you prefer to install system lsb-core or lsb-compat package then
 * uninstall CryptoPro CSP
 * install lsb-core or lsb-compat manually
 * install CryptoPro CSP again
"
}

construct_compat_package() {
    if [ -f /etc/cp-release ] ; then
        if grep Gaia /etc/cp-release > /dev/null 2>&1 ; then
            _distr="gaia"
        else
            _distr="splat"
        fi
    elif [ -f /etc/altlinux-release ] ; then
        _distr="altlinux${bits_postfix}"
    elif [ -f /etc/os-rt-release ] ; then
        _distr="osrt${bits_postfix}"
    elif [ "${is_arm}" -eq 1 ] ; then
        _distr="armhf"
    elif [ "${is_debian_system}" -eq 1 ] ; then
        if dpkg -s lsb-core > /dev/null 2>&1 ||
            dpkg -s lsb-compat > /dev/null 2>&1
        then
            compat_package=""
            return
        else
            lsb_warning
            _distr="debian"
        fi
    else
        compat_package=""
        return
    fi
    compat_package="cprocsp-compat-\
${_distr}\
${first_delimeter}\
${COMPAT_VERSION}\
${second_delimeter}\
${noarch}\
${extension}"
}

construct_other_packages() {
    other_packages=""
    _absent=""
    for _name in ${PACKAGE_NAMES} ; do
        _package="${_name}"
        if [ "${is_64_release}" -eq 1 ] ; then
            _package="${_package}${bits_postfix}"
        fi
        _package="${_package}\
${first_delimeter}\
${VERSION}\
${second_delimeter}\
${arch}\
${extension}"
        # There are several packages which are NOT architecture-specific,
        # e.g. lsb-cprocsp-base, lsb-cprocsp-ca-certs and devel-packages.
        # If the architecture-specific package is not found, try to install
        # the noarch package.
        # shellcheck disable=SC2086
        if ! [ -f ${_package} ] ; then
            _package="${_name}\
${first_delimeter}\
${VERSION}\
${second_delimeter}\
${noarch}\
${extension}"
        fi
        # Even the noarch package wasn't found.
        # shellcheck disable=SC2086
        if ! [ -f ${_package} ] ; then
            _absent="${_absent} ${_name}"
        else
            other_packages="${other_packages} ${_package}"
        fi
    done
    if ! [ -z "${_absent}" ] ; then
        echo "Error: the following packages are not available in the current directory:"
        echo "${_absent}" | xargs -n1 echo "*"
        exit "${PACKAGES_NOT_AVAILABLE}"
    fi
}

construct_list_of_packages() {
    packages=""
    construct_compat_package
    packages="${packages} ${compat_package}"
    # Other packages are the base packages and additional packages
    # specified by command-line arguments.
    construct_other_packages
    packages="${packages} ${other_packages}"
    # Remove duplicate packages.
    packages="$(
        echo "${packages}" \
            | awk '{for(i=1;i<=NF;i++)if(!a[$i]++)print $i}' | xargs
    )"
}

check_fail() {
    echo "Error: installation failed. LSB package may not be installed.
Install LSB package and reinstall CryptoPro CSP. If it does not help, please 
read installation documentation or contact the manufacturer: support@cryptopro.ru."
    exit "$1"
}

# Install packages one at a time before capilite, then batch install.
install_packages() {
    while ! [ -z "${packages}" ] ; do
        _head="$(echo "${packages}" | awk '{print $1}')"
        _tail="$(echo "${packages}" | awk '{for(i=2;i<=NF;i++)print $i}' | xargs)"
        echo "Installing ${_head}..." >&2
        # shellcheck disable=SC2086
        ${inst_cmd} ${_head} >&2 || check_fail "$?"
        if echo "${_head}" | grep capilite > /dev/null 2>&1 &&
            ! [ -z "${_tail}" ]
        then
            echo "Installing ${_tail}..." >&2
            # shellcheck disable=SC2086
            ${inst_cmd} ${_tail} >&2 || check_fail "$?"
            return
        fi
        packages="${_tail}"
    done
}

construct_list_of_packages_from_repository() {
    _tmp_repo="$(mktemp)"
    # Если файл со списком пакетов в репозитории существует и единственный, то скопировать его во временный файл _tmp_repo.
    # shellcheck disable=SC2144
    if [ -f /var/lib/apt/lists/cryptopro.ru_debrepo_dists_*-unstable_main_binary-*_Packages* ] ; then
        cp /var/lib/apt/lists/cryptopro.ru_debrepo_dists_*-unstable_main_binary-*_Packages* "${_tmp_repo}"
    fi
    # Если lz-архив со списком пакетов в репозитории существует и единственный, то разархивировать его во временный файл _tmp_repo.
    # shellcheck disable=SC2144
    if [ -f /var/lib/apt/lists/cryptopro.ru_debrepo_dists_*-unstable_main_binary-*_Packages*.lz ] ; then
        lzip -d -c /var/lib/apt/lists/cryptopro.ru_debrepo_dists_*-unstable_main_binary-*_Packages*.lz > "${_tmp_repo}"
    fi
    packages=""
    _absent=""
    for _name in ${PACKAGE_NAMES} ; do
        _package="${_name}${bits_postfix}"
        if ! grep 'Package:' "${_tmp_repo}" | grep "${_package}" > /dev/null 2>&1
        then
            _package="${_name}"
        fi
        if ! grep 'Package:' "${_tmp_repo}" | grep "${_package}" > /dev/null 2>&1
        then
            _absent="${_absent} ${_name}"
        else
            packages="${packages} ${_package}"
        fi
    done
    rm -f "${_tmp_repo}"
    if ! [ -z "${_absent}" ] ; then
        echo "Error: the following packages are not available in the current repository:"
        echo "${_absent}" | xargs -n1 echo "*"
        exit "${PACKAGES_NOT_AVAILABLE}"
    fi
    # Remove duplicate packages.
    packages="$(
        echo "${packages}" \
            | awk '{for(i=1;i<=NF;i++)if(!a[$i]++)print $i}' | xargs
    )"
}

main() {
    if [ "$(id -u)" -ne 0 ] ; then
        echo "Error: this script must be run as root"
        exit "${FAILURE}"
    fi
    cd "$(dirname "$0")" || check_fail "$?"
    parse_args "$@"
    which_architecture
    if [ "${FROM_REPO}" -eq 1 ] ; then
        construct_list_of_packages_from_repository
        sh ./uninstall.sh >&2 || check_fail "$?"
        # shellcheck disable=SC2086
        apt-get --yes install ${packages} >&2 || check_fail "$?"
        echo "CSP packages have been successfully installed from a repository"
        exit "${SUCCESS}"
    fi
    check_if_debian_system
    check_release_attributes
    set_inst_cmd
    set_release_variables
    construct_list_of_packages
    sh ./uninstall.sh >&2 || check_fail "$?"
    install_packages
    echo "CSP packages have been successfully installed"
    exit "${SUCCESS}"
}

main "$@"
