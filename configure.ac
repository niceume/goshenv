AC_INIT([prepare-goshenv], [0.9.0], toshi@niceume.com)
AC_CONFIG_SRCDIR([prepare-goshenv.sh.in])

[GOSHENV_UTILITY=$(cat ./sub/goshenv_utility.sh)]
[GOSHENV_INSTALL_GAUCHE=$(cat ./sub/goshenv_install_gauche.sh)]
[GOSHENV_CONTENT=$(cat ./goshenv)]
AC_SUBST([GOSHENV_UTILITY])
AC_SUBST([GOSHENV_INSTALL_GAUCHE])
AC_SUBST([GOSHENV_CONTENT])

AC_CONFIG_FILES([prepare-goshenv.sh])
AC_OUTPUT

