# Requires env PASSPHRASE to be set
ifeq ($(PASSPHRASE),)
$(error PASSPHRASE is not set)
endif

.PHONY: prepare gpgkey uninstall install
.DEFAULT_GOAL := prepare
exec_prefix := /usr/local
ORIGIN := 'MariaDB Platform QA'


prepare:
	install -m 644 rpmmacros $(HOME)/.rpmmacros
	install -d -m 700 $(HOME)/.gnupg
	install -m 600 gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	gpg-connect-agent reloadagent /bye ||:

uninstall:
	rm -f $(HOME)/.rpmmacros
	rm -f $(HOME)/.gnupg/gpg-agent.conf
	rm -f $(exec_prefix)/bin/signpackage
	rm -f $(exec_prefix)/bin/apt-repository

install: prepare
	install -m 755 signpackage $(exec_prefix)/bin
	install -m 755 apt-repository $(exec_prefix)/bin

gpgkey:
	@sed -e "s:@@PASSPHRASE@@:$(PASSPHRASE):g" < gpg-key-params > gpg-key-params.work
	gpg --verbose --batch --gen-key gpg-key-params.work
	rm -f gpg-key-params.work
	gpg --list-keys --keyid-format LONG
	gpg --export -a $(ORIGIN) > RPM-GPG-KEY-platform-qa
	gpg --export $(ORIGIN)    > deb-key-platform-qa.gpg
