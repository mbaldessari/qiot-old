.PHONY: default
default: help

.PHONY: help
# No need to add a comment here as help is described in common/
help:
	@printf "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) common/Makefile | sort | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)\n"

%:
	make -f common/Makefile $*

operator-install: operator-deploy post-install ## installs the pattern, inits the vault and loads the secrets
	echo "Installed"

install: legacy-deploy post-install ## install the pattern the old way without the operator
	echo "Installed"

post-install: ## Post-install tasks - vault init and load-secrets
	# FIXME(bandini): we let the QIOT bootstrap chart configure the vault
	# @if grep -v -e '^\s\+#' "values-hub.yaml" | grep -q -e "insecureUnsealVaultInsideCluster:\s\+true"; then \
	#   echo "Skipping 'make vault-init' as we're unsealing the vault from inside the cluster"; \
	# else \
	#   make vault-init; \
	# fi
	make load-secrets
	echo "Done"

common-test:
	make -C common -f common/Makefile test

test:
	make -f common/Makefile CHARTS="$(wildcard charts/all/*)" PATTERN_OPTS="-f values-global.yaml -f values-hub.yaml" test
	make -f common/Makefile CHARTS="$(wildcard charts/hub/*)" PATTERN_OPTS="-f values-global.yaml -f values-hub.yaml" test
	#make -f common/Makefile CHARTS="$(wildcard charts/region/*)" PATTERN_OPTS="-f values-region-one.yaml" test

helmlint:
	# no regional charts just yet: "$(wildcard charts/region/*)"
	@for t in "$(wildcard charts/*/*)"; do helm lint $$t; if [ $$? != 0 ]; then exit 1; fi; done

.PHONY: kubeconform
kubeconform:
	make -f common/Makefile CHARTS="$(wildcard charts/all/*)" kubeconform
	make -f common/Makefile CHARTS="$(wildcard charts/hub/*)" kubeconform
