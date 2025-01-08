function ensure_command {
    if ! hash $1 > /dev/null 2>&1 ; then
        echo "Error: $1 is not found. Please install it."
        exit 1
    fi
}

function ensure_command2 {
    if ! hash $1 > /dev/null 2>&1 ; then
        echo $2
        exit 1
    fi
}

function ensure_variable {
    if ! [[ -v $1 ]] ; then
        echo "Error: $1 varabile is not defined"
        exit 1
    fi
}

function ensure_variable2 {
    if ! [[ -v $1 ]] ; then
        echo $2
        exit 1
    fi
}

function create_dir_unless_exits {
    if [[ -d $1 ]] ; then
        : # nop
    else
        mkdir $1
        echo "$1 is created";
    fi
}

function goshenv_make_shims_from {
    ori_dir=$1
    for path in $(ls -d $ori_dir/*)
    do
        ln -s "$path" "$(basename $path)"
    done
}

function goshenv_filter_edge_versions {
    egrep [p0-9.\-]+\\+[0-9]+
}

function goshenv_filter_non_edge_versions {
    egrep -v [p0-9.\-]+\\+[0-9]+
}
