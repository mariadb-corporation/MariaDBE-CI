ifeq ($(PASSPHRASE),)
$(error PASSPHRASE is not set)
endif

gpgkey:
	@sed -e "s:@@PASSPHRASE@@:$(PASSPHRASE):g" < gpg-key-params > gpg-key-params.work
	gpg --verbose --batch --gen-key gpg-key-params.work
	rm -f gpg-key-params.work
	gpg --list-keys --keyid-format LONG
	gpg --export -a 'MariaDB Platform QA' > RPM-GPG-KEY-platform-qa
