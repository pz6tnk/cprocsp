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

# Exit codes.
SUCCESS=0
FAILURE=1

check_if_debian_system() {
    if [ -f /etc/debian_version ] ||
        grep Ubuntu /etc/lsb-release > /dev/null 2>&1
    then
        is_debian_system=1
    else
        is_debian_system=0
    fi
}

set_del_command_and_package_lists() {
    if [ "${is_debian_system}" -eq 1 ] ; then
        pkglist="$(dpkg -l | grep -e rtSupCP -e cprocsp | grep -v installer | awk '{print $2}')"
        pkglist_to_show="${pkglist}"
        del_command="dpkg -P"
    else
        # CPCSP-7978: пока в именах некоторых пакетов есть точки (например, версия ядра),
        # нужно удалять пакеты по полному названию, а не только по полю NAME.
        pkglist="$(rpm -qa | grep -e rtSupCP -e cprocsp | grep -v installer)"
        pkglist_to_show="$(rpm -qa --qf "%{NAME}\n" | grep -e rtSupCP -e cprocsp | grep -v installer)"
        del_command="rpm -e --allmatches"
    fi
    rdr_package="$(echo "${pkglist}" | grep lsb-cprocsp-rdr | grep -v -e accord -e sobol)"
    base_package="$(echo "${pkglist}" | grep base | grep -v ssl)"
    compat_package="$(echo "${pkglist}" | grep compat)"
    csp_packages="$(
        echo "${pkglist}" \
            | grep -vx -e "${rdr_package}" -e "${base_package}" -e "${compat_package}" \
            | xargs
    )"
}

check_fail() {
    echo "Error: failed to uninstall CSP packages"
    exit "$1"
}

main() {
    if [ "$(id -u)" -ne 0 ] ; then
        echo "Error: this script must be run as root"
        exit "${FAILURE}"
    fi
    check_if_debian_system
    set_del_command_and_package_lists
    if [ "$1" = "--list" ] ; then
        echo "${pkglist_to_show}" | sed 's/-64$//'
        exit "${SUCCESS}"
    fi
    echo "Uninstalling CSP packages..." >&2
    if [ -n "${csp_packages}" ] ; then
        # shellcheck disable=SC2086
        ${del_command} ${csp_packages} >&2 || check_fail "$?"
    fi
    if [ -n "${rdr_package}" ] ; then
        # shellcheck disable=SC2086
        ${del_command} ${rdr_package} >&2 || check_fail "$?"
    fi
    if [ -n "${base_package}" ] ; then
        # shellcheck disable=SC2086
        ${del_command} ${base_package} >&2 || check_fail "$?"
    fi
    if [ -n "${compat_package}" ] ; then
        # shellcheck disable=SC2086
        ${del_command} ${compat_package} >&2 || check_fail "$?"
    fi
    echo "CSP packages have been successfully uninstalled"
    exit "${SUCCESS}"
}

main "$@"
