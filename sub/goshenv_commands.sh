ensure_variable2 GOSHENV_HOME \
                 "GOSHENV_HOME needs to be defined before sourcing this file"

ensure_variable2 GAUCHE_API \
                 "GAUCHE_API needs to be defined before sourcing this file"

function goshenv-installed-verbose {
    current_use=`cat "$GOSHENV_HOME/db/current_use.txt"`
    
    for version in $(ls -r "$GOSHENV_HOME/gauche/")
    do
        if [[ $version = $current_use ]] ; then
            echo "$version (*)"
        else
            echo $version
        fi
    done
}

function goshenv-installed {    
    for version in $(ls -r "$GOSHENV_HOME/gauche/")
    do
        echo $version
    done
}

function goshenv-installable-verbose {
    current_use=$( cat "$GOSHENV_HOME/db/current_use.txt" )
    installed_pattern=$( ls "$GOSHENV_HOME/gauche/" | tr "\n" "|" | sed s/\|\$// )
    
    for version in $( cat "$GOSHENV_HOME/db/installable.txt" | tr "\n" " " )
    do
        if [[ $version = $current_use ]] ; then
            echo "$version (*)"
        elif echo $version | egrep -x $installed_pattern ; then
            echo "$version (#)"
        else
            echo $version
        fi
    done
}

function goshenv-installable {
    cat "$GOSHENV_HOME/db/installable.txt"
}

function goshenv-installable-edge-verbose {
    current_use=$( cat "$GOSHENV_HOME/db/current_use.txt" )
    installed_pattern=$( ls "$GOSHENV_HOME/gauche/" | tr "\n" "|" | sed s/\|\$// )
    
    for version in $( curl -L -f "$GAUCHE_API/.txt" 2> /dev/null \
                          | goshenv_filter_edge_versions \
                          | tr "\n" " " )
    do
        if [[ $version = $current_use ]] ; then
            echo "$version (*)"
        elif echo $version | egrep -x $installed_pattern ; then
            echo "$version (#)"
        else
            echo $version
        fi
    done
}

function goshenv-installable-edge {
    curl -L -f "$GAUCHE_API/.txt" 2> /dev/null | goshenv_filter_edge_versions
}

function goshenv-switch {
    version=$1
    mkdir -p "$GOSHENV_HOME/shims/bin"
    mkdir -p "$GOSHENV_HOME/shims/share/info"
    
    if goshenv-installed | grep -x $version ;
    then
        if ! cd "$GOSHENV_HOME/shims/bin/" ; then
            echo "$GOSHENV_HOME/shims/bin/ not found"
            exit 1
        fi
        rm -f ./*
        goshenv_make_shims_from "$GOSHENV_HOME/gauche/$version/bin"

        if ! cd "$GOSHENV_HOME/shims/share/info" ; then
            echo "$GOSHENV_HOME/shims/bin/ not found"
            exit 1
        fi
        rm -f ./*
        goshenv_make_shims_from "$GOSHENV_HOME/gauche/$version/share/info"

        echo $version > "$GOSHENV_HOME/db/current_use.txt"
        
        cd "$GOSHENV_HOME"
    else
        echo "Error: uninstalled version is specified"
        exit 1
    fi
}

function goshenv-install {
    version=$1
    configure_args=${@:2}

    if goshenv-installable | grep -x $version || \
            goshenv-installable-edge | grep -x $version ;
    then
        # the version is in installable list
        if [[ -d "$GOSHENV_HOME/gauche/$version" ]] ; then
            # the version is already installed
            echo "The version ($version) is already installed"
            exit 1
        else
            # the version is not installed yet
            :
        fi
    else
        # the version is not installable
        echo "The version ($version) is not in the installable list"
        echo "The version is not released yet or if it is released"
        echo "but is not listed in the local installable list,"
        echo "please update db by 'goshenv update-db' and try again"
        exit 1
    fi

    mkdir -p "$GOSHENV_HOME/temp"
    mkdir -p "$GOSHENV_HOME/gauche/$version"

    if [[ "$configure_args" =~ "--with-tls" ]]
    then
        : # the configure option already includes --with-tls option.
    else
        echo "--with-tls=mbedtls-internal is added to confiture argument"
        configure_args="--with-tls=mbedtls-internal $configure_args"
    fi

    $GOSHENV_HOME/script/sub/get-gauche.sh \
        --version $version \
        --prefix "$GOSHENV_HOME/gauche/$version" \
        --configure-args "$configure_args" \
        --force \
        --auto

    if ! [[ -f "$GOSHENV_HOME/gauche/$version/bin/gosh" ]] ; then
        # When installation failed
        echo "Error: get-gauche failed"
        rm -f -R "$GOSHENV_HOME/gauche/$version"
        exit 1
    else
        goshenv-switch $version
    fi
}

function goshenv-remove {
    version=$1
    if [[ $(cat "$GOSHENV_HOME/db/current_use.txt") == $version ]] ; then
        echo "$version is currently used, and is not removed"
        exit 1
    else
        if ! goshenv-installed | grep -x $version > /dev/null; then 
            echo "$version is not installed"
            exit 1
        else
            rm -R -f "$GOSHENV_HOME/gauche/$version"
            echo "$version is removed"
        fi
    fi
}

function goshenv-update-db {
    mkdir -p "$GOSHENV_HOME/db"
    curl -f -L $GAUCHE_API/.txt 2>/dev/null \
        | goshenv_filter_non_edge_versions > "$GOSHENV_HOME/db/installable.txt" 
}
