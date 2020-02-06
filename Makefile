# Requires PASSPHRASE to be set
.PHONY: prepare gpgkey uninstall install
.DEFAULT_GOAL := prepare
exec_prefix := /usr/local

prepare:
	install rpmmacros $(HOME)/.rpmmacros
	install -d -m 700 $(HOME)/.gnupg
	install -m 600 gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf
	killall -9 gpg-agent ||:

uninstall:
	rm -f $(HOME)/.rpmmacros
	rm -f $(HOME)/.gnupg/gpg-agent.conf
	rm -f $(exec_prefix)/bin

install:
	install -m 755 signpackage $(exec_prefix)/bin

gpgkey:
ifeq ($(PASSPHRASE),)
$(error PASSPHRASE is not set)
endif
	@sed -e "s:@@PASSPHRASE@@:$(PASSPHRASE):g" < gpg-key-params > gpg-key-params.work
	gpg --verbose --batch --gen-key gpg-key-params.work
	rm -f gpg-key-params.work
	gpg --list-keys --keyid-format LONG
	gpg --export -a 'MariaDB Platform QA' > RPM-GPG-KEY-platform-qa

