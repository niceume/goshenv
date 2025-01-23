# Setting

GET_GAUCHE_URI=https://raw.githubusercontent.com/practical-scheme/get-gauche/refs/heads/master/get-gauche.sh
GAUCHE_API=https://practical-scheme.net/gauche/releases
GOSHENV_HOME="$HOME/.goshenv"

# Arguments

# (e.g.)
# --version 0.9.15
# --with-slib /home/foo/SLIB/lib/slib
# --with-tls mbedtls-internal

non_option_args=()
while ! [[ $OPTIND -gt $# ]]; do
    optstring=":v:s:t:-:"
    long_options=(version: with-slib: with-tls: skip-tests allow-skip-info)
    while getopts $optstring  option; do

        # START logic to deal with long options
        if [[ $option = "-" ]]; then
            if [[ $OPTARG =~ ^[0-9a-zA-Z][0-9a-zA-Z_-]*= ]]; then
                option=${OPTARG%%=*}
                OPTARG=${OPTARG#*=}
            elif [[ $OPTARG =~ ^[0-9a-zA-Z][0-9a-zA-Z_-]* ]]; then
                option="${OPTARG}"
                if [[ " ${long_options[*]%:} " =~ " ${option} " ]] ; then
                    if [[ " ${long_options[*]} " =~ " ${option}: " ]] ; then
                        if ! [[ ${!OPTIND} =~ ^-.+ ]]; then
                            OPTARG=${!OPTIND}
                            OPTIND=$(( OPTIND + 1))
                        else
                            OPTARG=${!OPTIND}
                            OPTIND=$(( OPTIND + 1))
                        fi
                    else
                        OPTARG=""
                    fi
                else
                    if [[ ${optstring:0:1} = : ]] ; then
                        OPTARG=$option
                        option="?"
                    else
                        echo "$0: illegal option -- $option" 1>&2
                        option="?"
                        unset OPTARG
                    fi
                fi
            fi
        fi
        # END logic to deal with long options

        case $option in
            v|version)
                if ! [[ ${OPTARG} = "" ]] ; then
                    GAUCHE_VERSION=$OPTARG
                else
                    echo "-v|--version option requires value"
                    exit 1
                fi
                ;;
            s|with-slib)
                if ! [[ ${OPTARG} = "" ]] ; then
                    WITH_SLIB=$OPTARG
                else
                    echo "-s|--with-slib option requires value"
                    exit 1
                fi
                ;;
            t|with-tls)
                if ! [[ ${OPTARG} = "" ]] ; then
                    WITH_TLS=$OPTARG
                else
                    echo "-t|--with-tls option requires value"
                    exit 1
                fi
                ;;
            skip-tests)
                SKIP_TESTS="YES"
                ;;
            allow-skip-info)
                ALLOW_SKIP_INFO="YES"
                ;;
            \?)
                echo "unknown option ${option} ${OPTARG}"
                non_option_args+=('?')
                ;;
            *)
                echo "option: ${option} optarg: ${OPTARG} optind: ${OPTIND}"
                echo "unintentional parse error"
                exit 1
                ;;
        esac
    done

    # When non-option argument is encountered
    non_option_args+=(${!OPTIND})
    OPTIND=$((OPTIND + 1))
done

if ! [[ -z ${non_option_args[*]} ]]; then
    if [[ ${#non_option_args[@]} -eq 1 ]] && ! [[ $1 =~ ^- ]]; then
        # When the first argument is non optional argument
        if ! [[ -v GAUCHE_VERSION ]]; then
            GAUCHE_VERSION=$1
        else
            echo "Gauche version specification is duplicated"
            exit 1
        fi
    else
        echo "non used arguments found: ${non_option_args[*]}"
        echo "please check arguments and try installation again"
        exit 1
    fi
fi

## Default Values for variables

if ! [[ -v GAUCHE_VERSION ]] || [[ $GAUCHE_VERSION = "" ]] ; then
    GAUCHE_VERSION="latest"
fi

if ! [[ -v WITH_SLIB ]] || [[ $WITH_SLIB = "" ]] ; then
    WITH_SLIB="latest"
fi

if ! [[ -v WITH_TLS ]] || [[ $WITH_TLS = "" ]] ; then
    WITH_TLS="mbedtls-internal"
fi

# Command check

ensure_command curl
if ! echo $(uname) | grep -i "bsd" ; then
    ensure_command gmake
fi

if hash gmake; then
    MAKE=gmake
else
    MAKE=make
fi

if ! [[ $ALLOW_SKIP_INFO = "YES" ]]; then
    if ! hash makeinfo; then
        echo "Note: makeinfo is not found. It may be included in texinfo package."
        echo "Without makeinfo, info files cannot be created."
        echo "Run this script with --allow-skip-info or install makeinfo"
        exit 1
    fi
fi

if [[ $WITH_TLS = "mbedtls-internal" ]] ; then
    if ! hash cmake; then
        echo "Note: cmake is not found"
        echo "When '--with-tls=mbedtls-internal' is specified as a configure argument"
        echo "cmake is usually required to compile."
        echo "Do you want to proceed?"
        ask_proceed_or_exit
    fi
fi

# .goshenv directory

if [[ -v GOSHENV_ALREADY_INSTALLED ]] &&
       [[ $GOSHENV_ALREADY_INSTALLED = "YES" ]]; then
    : # GOSHENV is already installed
else
    create_dir_unless_exits "$GOSHENV_HOME"
    if [[ -f $GOSHENV_HOME/shims/bin/gosh ]] ; then
        echo "goshenv seems to be already installed"
        echo "If you need to reinstall goshenv, please remove ~/.goshenv directory first"
        exit 1
    fi
fi


# direcotries under .goshenv

mkdir -p "$GOSHENV_HOME/temp"
mkdir -p "$GOSHENV_HOME/gauche"
mkdir -p "$GOSHENV_HOME/slib"
mkdir -p "$GOSHENV_HOME/script/sub"
mkdir -p "$GOSHENV_HOME/shims"
mkdir -p "$GOSHENV_HOME/db"


# download slib if required

if [[ $WITH_SLIB = "none" ]] ; then
    echo "slib installation is skipped"
else
    if [[ $WITH_SLIB = "latest" ]] ; then
        WITH_SLIB=$(get_slib_latest)
    fi
    if [[ "$WITH_SLIB" =~ ^/ ]] ; then
        if [[ -d "$WITH_SLIB" ]] && [[ -f "$WITH_SLIB/require.scm" ]] ; then
            echo "slib path found: $WITH_SLIB"
        else
            echo "slib path not found: $WITH_SLIB"
            exit 1
        fi
    elif ! [[ $(get_slib_uri $WITH_SLIB) == "" ]] ; then
        SLIB_VERSION=$WITH_SLIB
        if [[ -f "$GOSHENV_HOME/slib/$SLIB_VERSION/lib/slib/require.scm" ]] ; then
            echo "slib $SLIB_VERSION found"
        else
            SLIB_URI=$(get_slib_uri $SLIB_VERSION)
            echo "download slib $SLIB_VERSION"
            if ! curl -f -L --progress-bar \
                 -o "$GOSHENV_HOME/temp/slib-${SLIB_VERSION}.tar.gz" $SLIB_URI ; then
                echo "slib download failed"
                exit 1
            fi
        fi
        WITH_SLIB="$GOSHENV_HOME/slib/$SLIB_VERSION/lib/slib/"
    else
        echo "unknown slib or relative path is specified: $WITH_SLIB"
        exit 1
    fi
fi


# download or copy get-gauche.sh from script/sub directory

if [[ -f $GOSHENV_HOME/script/sub/get-gauche.sh ]]; then
    cp $GOSHENV_HOME/script/sub/get-gauche.sh $GOSHENV_HOME/temp/get-gauche.sh
    chmod 755 "$GOSHENV_HOME/temp/get-gauche.sh"
else
    echo "download get-gauche.sh"
    if ! curl -L -f --progress-bar -o "$GOSHENV_HOME/temp/get-gauche.sh" $GET_GAUCHE_URI; then
        echo "get-gauche.sh download failed"
        if [[ -f "$GOSHENV_HOME/temp/get-gauche.sh" ]]; then
            rm -f "$GOSHENV_HOME/temp/get-gauche.sh"
        fi
        exit 1
    else
        chmod 755 "$GOSHENV_HOME/temp/get-gauche.sh"
    fi
fi


# cd temp

cd "$GOSHENV_HOME/temp"


# clean up temp directory when exit

function trap_exit {
    echo "exit goshenv installation process"
    if ! [[ "$GOSHENV_HOME" = "" ]] ; then
        echo "$GOSHENV_HOME"/temp/*
        rm -R -f "$GOSHENV_HOME"/temp/*
    fi
    echo "clean up .goshenv/temp directory"
}
trap trap_exit EXIT


# get-gauche.sh setting

if [[ $GAUCHE_VERSION = "latest" ]] ; then
    GAUCHE_VERSION=`curl -f -L $GAUCHE_API/latest.txt 2>/dev/null`
elif [[ $GAUCHE_VERSION = "snapshot" ]] ; then
    GAUCHE_VERSION=`curl -f -L $GAUCHE_API/snapshot.txt 2>/dev/null`
elif [[ $GAUCHE_VERSION = "bleeding" ]] ; then
    GAUCHE_VERSION=`curl -f -L $GAUCHE_API/bleeding.txt 2>/dev/null`
fi

GAUCHE_CONFIGURE_ARGS=""
if [[ -v WITH_SLIB ]] && ! [[ $WITH_SLIB = "" ]]; then
    GAUCHE_CONFIGURE_ARGS="$GAUCHE_CONFIGURE_ARGS --with-slib=${WITH_SLIB}"
fi
if [[ -v WITH_TLS ]] && ! [[ $WITH_TLS = "" ]]; then
    GAUCHE_CONFIGURE_ARGS="$GAUCHE_CONFIGURE_ARGS --with-tls=${WITH_TLS}"
fi

GET_GAUCHE_ADDITIONAL_OPTIONS=""
if [[ $SKIP_TESTS = "YES" ]]; then
    GET_GAUCHE_ADDITIONAL_OPTIONS="$GET_GAUCHE_ADDITIONAL_OPTIONS --skip-tests"
fi

curl -f -L $GAUCHE_API/.txt 2>/dev/null \
    | goshenv_filter_non_edge_versions > "$GOSHENV_HOME/db/installable.txt"

# Confirm installation

echo "-----------------------------------------------------"
echo "Gauche is to be installed with the following settings"
echo "version: $GAUCHE_VERSION"
echo "configure-args: $GAUCHE_CONFIGURE_ARGS"
if [[ $SKIP_TESTS = "YES" ]]; then
    echo "tests: skipped"
fi
if [[ $ALLLOW_SKIP_INFO = "YES" ]] && ! hash makeinfo; then
    echo "info files: not generated"
fi
echo "-----------------------------------------------------"
ask_proceed_or_exit


# install slib if required

if [[ -v SLIB_VERSION ]] ; then
    if [[ -f "$GOSHENV_HOME/slib/$SLIB_VERSION/lib/slib/require.scm" ]] ; then
        echo "slib $SLIB_VERSION is found"
    else
        mkdir "$GOSHENV_HOME/temp/slib"
        tar zxf "$GOSHENV_HOME/temp/slib-${SLIB_VERSION}.tar.gz" \
            -C "$GOSHENV_HOME/temp/slib" --strip-components=1
        current_dir=$(pwd)
        cd "$GOSHENV_HOME/temp/slib"
        mkdir -p "$GOSHENV_HOME/slib/$SLIB_VERSION"
        ./configure --prefix="$GOSHENV_HOME/slib/$SLIB_VERSION"
        if hash makeinfo; then
            $MAKE install-infoz
        fi
        touch -m clrnamdb.scm
        $MAKE install-lib
        cd "$current_dir"
    fi
fi

# get-gauche.sh

mkdir -p "$GOSHENV_HOME/gauche/$GAUCHE_VERSION"
./get-gauche.sh --prefix "$GOSHENV_HOME/gauche/$GAUCHE_VERSION" \
                --version $GAUCHE_VERSION \
                --configure-args "$GAUCHE_CONFIGURE_ARGS" \
                --force \
                --auto \
                $GET_GAUCHE_ADDITIONAL_OPTIONS
