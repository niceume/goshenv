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

function ask_proceed_or_exit {
    select yn in "Proceed" "Exit"; do
        case $yn in
            Proceed ) break;;
            Exit ) exit;;
        esac
    done
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

function get_slib_latest {
    echo "3c1"
}

function get_slib_uri {
    case $1 in
        3c1)
            echo "https://groups.csail.mit.edu/mac/ftpdir/scm/slib-3c1.tar.gz"
            ;;
        3b7)
            echo "https://groups.csail.mit.edu/mac/ftpdir/scm/slib-3b7.tar.gz"
            ;;
        3b6)
            echo "https://groups.csail.mit.edu/mac/ftpdir/scm/slib-3b6.tar.gz"
            ;;
        3b5)
            echo "https://groups.csail.mit.edu/mac/ftpdir/scm/slib-3b5.tar.gz"
            ;;
        3b4)
            echo "https://groups.csail.mit.edu/mac/ftpdir/scm/slib-3b4.tar.gz"
            ;;
        *)
            echo ""
            ;;
    esac
}
