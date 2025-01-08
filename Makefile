RM = rm -f -R

SCRIPTS = sub/goshenv_commands.sh sub/goshenv_main.sh sub/goshenv_utility.sh

.PHONY : all build distclean

all : goshenv-init prepare-goshenv

goshenv-init : release/goshenv-init.tgz

prepare-goshenv : release/prepare-goshenv.sh

release/prepare-goshenv.sh : prepare-goshenv.sh.in configure
	bash ./configure
	mv prepare-goshenv.sh release/prepare-goshenv.sh

configure : configure.ac
	autoconf

release/goshenv-init.tgz : $(SCRIPTS)
	tar -czf $@ $^  

distclean :
	$(RM) *~
	$(RM) *.cache *.log *.status
	$(RM) configure
	$(RM) release/goshenv-init.tgz
	$(RM) release/prepare-goshenv.sh
