source $GOSHENV_HOME/script/sub/goshenv_utility.sh
source $GOSHENV_HOME/script/sub/goshenv_commands.sh

case $1 in
    installed)
        goshenv-installed-verbose
        ;;
    installable)
        goshenv-installable-verbose
        ;;
    installable-edge)
        goshenv-installable-edge-verbose
        ;;
    install)
        goshenv-install "${@:2}"
        ;;
    switch)
        goshenv-switch $2
        ;;
    remove)
        goshenv-remove $2
        ;;
    update-db)
        goshenv-update-db
        ;;
    help)
        cat <<EOF
goshenv command help
installed        : list installed versions
installable      : list installable versions (snapshot/release)
installable-edge : list installable edge versions
install <version> <install-options>
install <install-options>
                 : install Gauche following <install-options>
switch <version> : switch to use <version>
remove <version> : remove <version>
update-db        : update db info (installable version list)
EOF
        ;;
    *)
        echo "unknown goshenv command: $1"
        echo "'goshenv help' shows how to use goshenv"
        ;;
esac
