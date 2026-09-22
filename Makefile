.PHONY: check test build dmg verify source integration ui previews
check:
	python3 scripts/privacy-check.py
	for script in scripts/*.sh; do bash -n "$$script" || exit; done

test:
	bash scripts/test.sh

build:
	bash scripts/build.sh

dmg:
	bash scripts/package-dmg.sh

verify:
	bash scripts/verify-dmg.sh

source:
	python3 scripts/export-source.py

integration:
	bash scripts/test-integration.sh

ui:
	bash scripts/test-ui.sh

previews:
	bash scripts/render-previews.sh
