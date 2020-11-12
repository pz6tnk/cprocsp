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

WIDTH=78
HEIGHT=20

# Exit codes.
SUCCESS=0
FAILURE=1
PACKAGES_NOT_AVAILABLE=2

test_whiptail_and_scripts() {
    if ! command -v whiptail > /dev/null 2>&1 ; then
        echo "Error: whiptail wasn't found" >&2
        exit "${FAILURE}"
    fi
    if ! ls ./install.sh ./uninstall.sh > /dev/null 2>&1 ; then
        echo "Error: necessary scripts were not found"
        exit "${FAILURE}"
    fi
    # shellcheck disable=SC2016
    if ! grep '"$1" = "--list"' ./uninstall.sh > /dev/null 2>&1 ; then
        echo "Error: uninstall script doesn't support querying packages"
        exit "${FAILURE}"
    fi
    if ! grep 'from-repo' ./install.sh > /dev/null 2>&1 ; then
        echo "Error: install script doesn't support installing from repository"
        exit "${FAILURE}"
    fi
}

check_license() {
    license="$(/opt/cprocsp/sbin/"${ARCH}"/cpconfig -license -view 2>&1)"
    if [ "$?" -eq "${SUCCESS}" ] ; then
        license_output="Check license successful

${license}"
    else
        license_output="Check license error

${license}"
    fi
}

ask_about_license() {
    whiptail --title "CryptoPro CSP Setup" \
        --yesno "Would you like to enter the license now, or postpone it for a while?" \
        --yes-button "Enter the license now" --no-button "Later" \
        "${HEIGHT}" "${WIDTH}" 
    if [ "$?" -ne "${SUCCESS}" ] ; then
        choose_activity${FROM_REPO_FUNC}
        return
    fi
    check_license
    license_menu
}

install_notification() {
    whiptail --title "CryptoPro CSP Setup" \
        --msgbox "${install_log}" \
        --ok-button "Ok" \
        "${HEIGHT}" "${WIDTH}"
    if [ "${install_status}" -eq "${SUCCESS}" ] ; then
        ask_about_license
    else
        main_menu
    fi
}

wrong_packages() {
    whiptail --title "CryptoPro CSP Setup" \
        --msgbox "At least one of the following packages must be selected:

* KC1 Cryptographic Service Provider
* KC2 Cryptographic Service Provider" \
        --ok-button "Ok" \
        "${HEIGHT}" "${WIDTH}"
    select_packages${SUITE}
}

install_confirmation_intel() {
    whiptail --title "CryptoPro CSP Setup" \
        --yesno "The following features will be installed:

${feature_descriptions}
Click Install to begin the installation. If you want to change your installation settings, click Back." \
        --yes-button "Install" --no-button "Back" \
        "${HEIGHT}" "${WIDTH}" 
    if [ "$?" -ne "${SUCCESS}" ] ; then
        select_packages${SUITE}
        return
    fi
    packages=""
    for feature_key in ${feature_keys} ; do
        case "${feature_key}" in
            "rdr")
                packages="${packages} cprocsp-rdr-pcsc cprocsp-rdr-emv cprocsp-rdr-inpaspot cprocsp-rdr-mskey cprocsp-rdr-novacard cprocsp-rdr-rutoken"
                ;;
            "ssl")
                packages="${packages} cprocsp-cpopenssl-base cprocsp-cpopenssl cprocsp-cpopenssl-gost"
                ;;
            *)
                packages="${packages} ${feature_key}"
                ;;
        esac
    done
    if echo "${packages}" | grep -v kc1 | grep kc2 > /dev/null 2>&1 ; then
        kc="kc2"
    else
        kc="kc1"
    fi
    # shellcheck disable=SC2086
    install_log="$(./install.sh ${FROM_REPO_OPT} ${kc} ${packages})"
    install_status="$?"
    install_notification
}

select_packages_intel() {
    feature_keys="$(
        whiptail --title "CryptoPro CSP Setup" \
            --checklist "Select the way you want features to be installed.

Click on the list items below to change the way features will be installed." \
            --ok-button "Next" --cancel-button "Exit" \
            "${HEIGHT}" "${WIDTH}" 7 --notags --separate-output \
            "lsb-cprocsp-kc1" "KC1 Cryptographic Service Provider" "ON" \
            "lsb-cprocsp-kc2" "KC2 Cryptographic Service Provider" "OFF" \
            "cprocsp-rdr-gui-gtk" "GUI for smart card and token support modules" "OFF" \
            "rdr" "Smart Card and Token support modules" "OFF" \
            "ssl" "OpenSSL library" "OFF" \
            "cprocsp-stunnel" "stunnel, SSL/TLS tunnel with GOST support" "OFF" \
            "lsb-cprocsp-pkcs11" "PKCS #11 library" "OFF" \
            3>&1 1>&2 2>&3
    )"
    if [ "$?" -ne "${SUCCESS}" ] ; then
        previous="select_packages_intel" ; exit_confirmation
        return
    fi
    count="$(echo "${feature_keys}" | grep -c 'kc[1-2]')"
    if [ "${count}" -ne 0 ] ; then
        feature_descriptions=""
        for feature_key in ${feature_keys} ; do
            case "${feature_key}" in
                "lsb-cprocsp-kc1")
                    description="KC1 Cryptographic Service Provider"
                    ;;
                "lsb-cprocsp-kc2")
                    description="KC2 Cryptographic Service Provider"
                    ;;
                "cprocsp-rdr-gui-gtk")
                    description="GUI components for smart card and token support modules"
                    ;;
                "rdr")
                    description="Smart Card and Token support modules"
                    ;;
                "ssl")
                    description="OpenSSL library"
                    ;;
                "cprocsp-stunnel")
                    description="stunnel, SSL/TLS tunnel with GOST support"
                    ;;
                "lsb-cprocsp-pkcs11")
                    description="PKCS #11 library"
                    ;;
            esac
            feature_descriptions="${feature_descriptions}* ${description}
"
        done
        install_confirmation${SUITE}
    else
        wrong_packages
    fi
}

install_confirmation() {
    whiptail --title "CryptoPro CSP Setup" \
        --yesno "The following features will be installed:

${feature_descriptions}
Click Install to begin the installation. If you want to change your installation settings, click Back." \
        --yes-button "Install" --no-button "Back" \
        "${HEIGHT}" "${WIDTH}" 
    if [ "$?" -ne "${SUCCESS}" ] ; then
        select_packages${SUITE}
        return
    fi
    packages=""
    for feature_key in ${feature_keys} ; do
        case "${feature_key}" in
            "rdr")
                packages="${packages} cprocsp-rdr-pcsc"
                ;;
            *)
                packages="${packages} ${feature_key}"
                ;;
        esac
    done
    if echo "${packages}" | grep -v kc1 | grep kc2 > /dev/null 2>&1 ; then
        kc="kc2"
    else
        kc="kc1"
    fi
    # shellcheck disable=SC2086
    install_log="$(./install.sh ${FROM_REPO_OPT} ${kc} ${packages})"
    install_status="$?"
    install_notification
}

select_packages() {
    feature_keys="$(
        whiptail --title "CryptoPro CSP Setup" \
            --checklist "Select the way you want features to be installed.

Click on the list items below to change the way features will be installed." \
            --ok-button "Next" --cancel-button "Exit" \
            "${HEIGHT}" "${WIDTH}" 6 --notags --separate-output \
            "lsb-cprocsp-kc1" "KC1 Cryptographic Service Provider" "ON" \
            "lsb-cprocsp-kc2" "KC2 Cryptographic Service Provider" "OFF" \
            "cprocsp-rdr-gui-gtk" "GUI components for smart card and token support modules" "OFF" \
            "rdr" "Smart Card and Token support modules" "OFF" \
            "cprocsp-stunnel" "stunnel, SSL/TLS tunnel with GOST support" "OFF" \
            "lsb-cprocsp-pkcs11" "PKCS #11 library" "OFF" \
            3>&1 1>&2 2>&3
    )"
    if [ "$?" -ne "${SUCCESS}" ] ; then
        previous="select_packages" ; exit_confirmation
        return
    fi
    count="$(echo "${feature_keys}" | grep -c 'kc[1-2]')"
    if [ "${count}" -ne 0 ] ; then
        feature_descriptions=""
        for feature_key in ${feature_keys} ; do
            case "${feature_key}" in
                "lsb-cprocsp-kc1")
                    description="KC1 Cryptographic Service Provider"
                    ;;
                "lsb-cprocsp-kc2")
                    description="KC2 Cryptographic Service Provider"
                    ;;
                "cprocsp-rdr-gui-gtk")
                    description="GUI components for smart card and token support modules"
                    ;;
                "rdr")
                    description="Smart Card and Token support modules"
                    ;;
                "cprocsp-stunnel")
                    description="stunnel, SSL/TLS tunnel with GOST support"
                    ;;
                "lsb-cprocsp-pkcs11")
                    description="PKCS #11 library"
                    ;;
            esac
            feature_descriptions="${feature_descriptions}* ${description}
"
        done
        install_confirmation${SUITE}
    else
        wrong_packages
    fi
}

reinstall_notification() {
    whiptail --title "CryptoPro CSP Setup" \
        --msgbox "${reinstall_log}" \
        --ok-button "Ok" \
        "${HEIGHT}" "${WIDTH}"
    choose_activity${FROM_REPO_FUNC}
}

reinstall_cut_package_list() {
    whiptail --title "CryptoPro CSP Setup" \
        --yesno "${reinstall_log}

These packages will be removed. Proceed with the reinstallation?" \
        --yes-button "Yes" --no-button "No" \
        "${HEIGHT}" "${WIDTH}" 
    if [ "$?" -ne "${SUCCESS}" ] ; then
        choose_activity${FROM_REPO_FUNC}
        return
    fi
    # shellcheck disable=SC2063
    unavailable="$(echo "${reinstall_log}" | grep '^*' | sed 's/*//' | xargs)"
    packages="$(echo "${packages}" "${unavailable}" | xargs -n1 | sort | uniq -u | xargs)"
    # shellcheck disable=SC2086
    reinstall_log="$(./install.sh ${FROM_REPO_OPT} ${kc} ${packages})"
    reinstall_notification
}

reinstall_confirmation() {
    whiptail --title "CryptoPro CSP Setup" \
        --yesno "Reinstall CryptoPro CSP

You have chosen to reinstall your current CryptoPro CSP installation.

Click Reinstall to reinstall CryptoPro CSP. If you want to review or change any of your installation changes, click Back." \
        --yes-button "Reinstall" --no-button "Back" \
        "${HEIGHT}" "${WIDTH}" --defaultno
    if [ "$?" -ne "${SUCCESS}" ] ; then
        choose_activity${FROM_REPO_FUNC}
        return
    fi
    packages="$(./uninstall.sh --list | grep -v compat | xargs)"
    if echo "${packages}" | grep -v kc1 | grep kc2 > /dev/null 2>&1 ; then
        kc="kc2"
    else
        kc="kc1"
    fi
    # shellcheck disable=SC2086
    reinstall_log="$(./install.sh ${FROM_REPO_OPT} ${kc} ${packages})"
    reinstall_status="$?"
    if [ "${reinstall_status}" -eq "${PACKAGES_NOT_AVAILABLE}" ] ; then
        reinstall_cut_package_list
    else
        reinstall_notification
    fi
}

uninstall_notification() {
    whiptail --title "CryptoPro CSP Setup" \
        --msgbox "${uninstall_log}" \
        --ok-button "Ok" \
        "${HEIGHT}" "${WIDTH}"
    main_menu
}

uninstall_confirmation() {
    whiptail --title "CryptoPro CSP Setup" \
        --yesno "Uninstall CryptoPro CSP

You have chosen to uninstall the program from your computer.

Click Uninstall to uninstall CryptoPro CSP from your computer. If you want to review or change any of your installation changes, click Back." \
        --yes-button "Uninstall" --no-button "Back" \
        "${HEIGHT}" "${WIDTH}" --defaultno
    if [ "$?" -ne "${SUCCESS}" ] ; then
        choose_activity${FROM_REPO_FUNC}
        return
    fi
    uninstall_log="$(./uninstall.sh)"
    uninstall_notification
}

input_license_finished() {
    whiptail --title "CryptoPro CSP Setup" \
        --msgbox "${license_output}" \
        --ok-button "Ok" \
        "${HEIGHT}" "${WIDTH}"
    choose_activity${FROM_REPO_FUNC}
}

license_menu() {
    serial_number="$(
        whiptail --title "CryptoPro CSP Setup" \
            --inputbox "${license_output}

Enter the license serial number:" \
            --ok-button "Enter" --cancel-button "Cancel" \
            "${HEIGHT}" "${WIDTH}" \
            3>&1 1>&2 2>&3
    )"
    if [ "$?" -ne "${SUCCESS}" ] ; then
        choose_activity${FROM_REPO_FUNC}
        return
    fi
    license="$(/opt/cprocsp/sbin/"${ARCH}"/cpconfig -license -set "${serial_number}" 2>&1)"
    if [ "$?" -eq "${SUCCESS}" ] ; then
        license_output="License was set

${license}"
    else
        license_output="Error setting license

${license}"
    fi
    input_license_finished
}

rmrepo_notification() {
    whiptail --title "CryptoPro CSP Setup" \
        --msgbox "CryptoPro packages and repository have been removed" \
        --ok-button "Ok" \
        "${HEIGHT}" "${WIDTH}"
    main_menu
}

rmrepo_confirmation() {
    whiptail --title "CryptoPro CSP Setup" \
        --yesno "Uninstall CryptoPro CSP packages and repository

Click Uninstall to uninstall CryptoPro CSP and remove the CryptoPro CSP repository from your computer. If you want to review or change any of your installation changes, click Back." \
        --yes-button "Uninstall" --no-button "Back" \
        "${HEIGHT}" "${WIDTH}" --defaultno
    if [ "$?" -ne "${SUCCESS}" ] ; then
        choose_activity${FROM_REPO_FUNC}
        return
    fi
    ./uninstall.sh
    sed -i '/cryptopro/d' /etc/apt/sources.list
    for _source in /etc/apt/sources.list.d/* ; do
        sed -i '/cryptopro/d' "${_source}"
    done
    [ -s /etc/apt/sources.list.d/cprocsp.list ] || rm -f /etc/apt/sources.list.d/cprocsp.list
    apt-key del "$(apt-key list | grep -B 1 CryptoPro | head -1)"
    apt-get update
    rmrepo_notification
}

choose_activity() {
    choice="$(
        whiptail --title "CryptoPro CSP Setup" \
            --menu "Select the operation you wish to perform." \
            --ok-button "Select" --cancel-button "Exit" \
            "${HEIGHT}" "${WIDTH}" 3 --notags\
            "Reinstall" "Reinstall CSP packages" \
            "Uninstall" "Uninstall CSP packages" \
            "License" "Enter or check license" \
            3>&1 1>&2 2>&3
    )"
    if [ "$?" -ne "${SUCCESS}" ] ; then
        previous="choose_activity" ; exit_confirmation
        return
    fi
    case "${choice}" in
        "Reinstall")
            reinstall_confirmation
            ;;
        "Uninstall")
            uninstall_confirmation
            ;;
        "License")
            check_license
            license_menu
            ;;
    esac
}

choose_activity_from_repo() {
    choice="$(
        whiptail --title "CryptoPro CSP Setup" \
            --menu "Select the operation you wish to perform." \
            --ok-button "Select" --cancel-button "Exit" \
            "${HEIGHT}" "${WIDTH}" 4 --notags\
            "Reinstall" "Reinstall CSP packages" \
            "Uninstall" "Uninstall CSP packages" \
            "Rmrepo" "Uninstall CSP packages and remove CSP repository" \
            "License" "Enter or check license" \
            3>&1 1>&2 2>&3
    )"
    if [ "$?" -ne "${SUCCESS}" ] ; then
        previous="choose_activity_from_repo" ; exit_confirmation
        return
    fi
    case "${choice}" in
        "Reinstall")
            reinstall_confirmation
            ;;
        "Uninstall")
            uninstall_confirmation
            ;;
        "Rmrepo")
            rmrepo_confirmation
            ;;
        "License")
            check_license
            license_menu
            ;;
    esac
}

exit_confirmation() {
    whiptail --title "CryptoPro CSP Setup" \
        --yesno "Are you sure you want to exit the CryptoPro CSP Setup Wizard?" \
        --yes-button "Yes" --no-button "No" \
        "${HEIGHT}" "${WIDTH}" --defaultno
    if [ "$?" -ne "${SUCCESS}" ] ; then
        ${previous}
        return
    fi
    exit "${SUCCESS}"
}

add_repo_notification() {
    whiptail --title "CryptoPro CSP Setup" \
        --msgbox "${add_repo_notification}" \
        --ok-button "Ok" \
        "${HEIGHT}" "${WIDTH}"
    if [ "${add_repo_status}" -ne "${SUCCESS}" ] ; then
        sed -i '/cryptopro/d' /etc/apt/sources.list
        for _source in /etc/apt/sources.list.d/* ; do
            sed -i '/cryptopro/d' "${_source}"
        done
        [ -s /etc/apt/sources.list.d/cprocsp.list ] || rm -f /etc/apt/sources.list.d/cprocsp.list
        apt-key del "$(apt-key list | grep -B 1 CryptoPro | head -1)"
        apt-get update
        add_repository
        return
    fi
    if [ "$(./uninstall.sh --list | wc -w)" -eq 0 ] ; then
        select_packages${SUITE}
    else
        choose_activity${FROM_REPO_FUNC}
    fi
}

ask_password() {
    password="$(
        whiptail --title "CryptoPro CSP Setup" \
            --passwordbox "Enter your password:" \
            --ok-button "Enter" --cancel-button "Cancel" \
            "${HEIGHT}" "${WIDTH}" \
            3>&1 1>&2 2>&3
    )"
    if [ "$?" -ne "${SUCCESS}" ] ; then
        add_repository
        return
    fi
    wget -q -O - https://www.cryptopro.ru/sites/default/files/products/csp/cryptopro_key.pub | apt-key add -
    echo "deb https://${username}:${password}@cryptopro.ru/debrepo 4.0-unstable main" > /etc/apt/sources.list.d/cprocsp.list
    apt-get update
    add_repo_status="$?"
    [ "${add_repo_status}" -eq "${SUCCESS}" ] && add_repo_notification="CryptoPro repository has been added" || add_repo_notification="Failed to add CryptoPro repository. Check your username and password"
    add_repo_notification
}

ask_username() {
    username="$(
        whiptail --title "CryptoPro CSP Setup" \
            --inputbox "Enter your username:" \
            --ok-button "Enter" --cancel-button "Cancel" \
            "${HEIGHT}" "${WIDTH}" \
            3>&1 1>&2 2>&3
    )"
    if [ "$?" -ne "${SUCCESS}" ] ; then
        add_repository
        return
    fi
    ask_password
}

add_repository() {
    whiptail --title "CryptoPro CSP Setup" \
        --yesno "You have chosen the installation from a repository which have not been added yet.

Would you like to add the repository now?" \
        --yes-button "Add" --no-button "Exit" \
        "${HEIGHT}" "${WIDTH}" 
    if [ "$?" -ne "${SUCCESS}" ] ; then
        previous="add_repository" ; exit_confirmation
        return
    fi
    ask_username
}

main_menu() {
    whiptail --title "CryptoPro CSP Setup" \
        --yesno "Welcome to the CryptoPro CSP Setup Wizard

The Setup Wizard will allow you to install, reinstall or remove CryptoPro CSP from your computer. Click Next to continue or Exit to exit the Setup Wizard." \
        --yes-button "Next" --no-button "Exit" \
        "${HEIGHT}" "${WIDTH}" 
    if [ "$?" -ne "${SUCCESS}" ] ; then
        previous="main_menu" ; exit_confirmation
        return
    fi
    if [ "${FROM_REPO_OPT}" = "--from-repo" ] ; then
        if ! grep cryptopro /etc/apt/sources.list > /dev/null 2>&1 &&
            ! grep -r cryptopro /etc/apt/sources.list.d/ > /dev/null 2>&1
        then
            add_repository
            return
        fi
    fi
    if [ "$(./uninstall.sh --list | wc -w)" -eq 0 ] ; then
        select_packages${SUITE}
    else
        choose_activity${FROM_REPO_FUNC}
    fi
}

main() {
    if [ "$(id -u)" -ne 0 ] ; then
        echo "Error: this script must be run as root"
        exit "${FAILURE}"
    fi
    cd "$(dirname "$0")" || exit "$?"
    test_whiptail_and_scripts
    case "$(uname -m)" in
        "x86_64"|"amd64")
            ARCH="amd64"
            ;;
        "ppc64"|"ppc64le")
            ARCH="$(uname -m)"
            ;;
        arm*)
            ARCH="arm"
            ;;
        "mips")
            ARCH="mipsel"
            ;;
        *)
            ARCH="ia32"
            ;;
    esac
    case "$(uname -m)" in
        arm*|"mips"|"ppc64"|"ppc64le")
            SUITE=""
            ;;
        *)
            SUITE="_intel"
            ;;
    esac
    if [ "$1" = "--from-repo" ] ; then
        FROM_REPO_OPT="--from-repo"
        FROM_REPO_FUNC="_from_repo"
    else
        FROM_REPO_OPT=""
        FROM_REPO_FUNC=""
    fi
    main_menu
}

main "$@"
