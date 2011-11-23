# Top-level Makefile for Treacherous Talks

# Path to rebar
REBAR=./rebar

# Path to system release folder where releases are put
SYSREL=system-release

# Internal variables used for naming release tar
DATE=`date +%Y%m%d-%H%M`
COMMIT=$(shell git diff-index --quiet HEAD; \
               if [ $$? -ne 0 ]; then echo dirty; \
               else git rev-list --max-count=1 HEAD; fi)


standard: small_clean get_deps compile docs
	@echo ok

complete: standard test release tar_release
	@echo ok

plt:
	@if [ ! -f ~/.dialyzer_plt ]; then                            \
	  echo "################################################";    \
	  echo "WARNING: ~/.dialyzer_plt was not found";              \
	  echo "I am building it for you."                            \
	  echo "This will take a while (this time).";                 \
	  sleep 3;                                                    \
	  echo "You might as well make some coffee..";                \
	  sleep 2;                                                    \
	  time dialyzer --build_plt --apps erts kernel stdlib mnesia; \
	fi
	 # delete the .eunit dirs, they confuse dialyzer:
	find apps -name .eunit -type d -exec rm -rf '{}' \;
	$(REBAR) compile
	@echo "######################"
	@echo "building apps/apps.plt"
	dialyzer -r apps --build_plt --output_plt apps/apps.plt || echo ""

dia:
	dialyzer --plts apps/apps.plt ~/.dialyzer_plt -- -r apps

### Build rules

# Do a special fetch for Yaws since we cannot use it with rebar. Ignore clone
# errors since they only mean that we already have cloned it
get_deps:
	$(REBAR) get-deps
	cd deps; git clone https://github.com/ahilsend/yaws.git 2>&1 || echo ok
	cd deps/yaws; git checkout websocket_hy10 2>&1

# Build Yaws in the old boring way and in parallel with make -j4
compile:
	cd deps/yaws; autoconf
	cd deps/yaws; ./configure --disable-pam
	cd deps/yaws; make -j4
	$(REBAR) compile
	cd ext_test/ejabberd_echo/; ../../$(REBAR) compile
	cd ext_test/smtp_integration_test/; ../../$(REBAR) compile

docs:
	$(REBAR) doc skip_deps=true

small_clean:
	$(REBAR) clean skip_deps=true

clean:
	$(REBAR) clean


### Test rules

test: unittest inttest

unittest:
	$(REBAR) eunit skip_deps=true

# This rule runs a bash script that actually perform the integration tests
inttest: release
	cd ext_test; bash test


### Release rules

release: clean_release copy_docs
	$(REBAR) generate

clean_release:
	rm -rf $(SYSREL)/*

# This rule copies docs to SYSREL/docs so that they are easier to collect for
# Buildbot
copy_docs:
	rm -rf $(SYSREL)/docs
	mkdir -p $(SYSREL)/docs
	for dir in apps/*/doc/edoc-info; \
	do path=$$(dirname $$dir); name=$$(basename $$(dirname $$path)); \
	cp -r $$path $(SYSREL)/docs/$$name; done;

# Create a tar.gz file of all releases in SYSREL
tar_release:
	rm -f $(SYSREL)/release-*.tar.gz
	tar -czf $(SYSREL)/release-$(DATE)-$(COMMIT).tar.gz system-release/*

# Create a stupid deb package of all releases in SYSREL using the tool fpm. It
# can be installed via a gem, run "gem install fpm". Beware that you might need
# to add the gem bin directory to your $PATH, such as /var/lib/gems/1.8/bin.
deb_release:
	rm -f $(SYSREL)/*.deb
	cd $(SYSREL); fpm -s dir -t deb -n treacherous-talks --prefix /opt/tt \
	-v $(DATE)-$(COMMIT) *


### Helper rules for internal development

create_deps_file: clean get_deps
	tar -czf dependencies.tar.gz deps/

fetch_deps_file:
	wget -nv 'http://buildbot.pcs/mirror/dependencies.tar.gz' 2>&1
	tar -xf dependencies.tar.gz
	rm dependencies.tar.gz

.PHONY: standard complete get_deps compile docs small_clean clean test \
	unittest inttest release clean_release copy_docs tar_release \
	deb_release create_deps_file fetch_deps_file plt dia
