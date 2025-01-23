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
    GOSHENV_ALREADY_INSTALLED="YES"
    source "$GOSHENV_HOME/script/sub/goshenv_install_gauche.sh"

    if ! [[ -f "$GOSHENV_HOME/gauche/$GAUCHE_VERSION/bin/gosh" ]] ; then
        # When installation failed
        rm -R -f "$GOSHENV_HOME/gauche/$GAUCHE_VERSION/"
        echo "Gauche $GAUCHE_VERSION installation fails"
        echo "Please make sure installation arguments are valid"
        exit 1
    else
        goshenv-switch $GAUCHE_VERSION
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
