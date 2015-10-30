NAME = task
VERSION = 2.5.0
SOURCE_URL = http://taskwarrior.org/download/$(NAME)-$(VERSION).tar.gz
PACKAGE_URL = http://taskwarrior.org/
PACKAGE_DESCRIPTION = Taskwarrior manages your TODO list from your command line.
LICENSE = MIT
ITERATION = 1

BUILD_DIR := $(CURDIR)/build
CACHE_DIR = cache
PACKAGE_DIR = pkg
TARBALL = $(CACHE_DIR)/$(notdir $(SOURCE_URL))
SOURCE_DIR = $(CACHE_DIR)/$(NAME)-$(VERSION)
PACKAGE_TYPE = deb
PREFIX = /usr/local
RELATIVE_PREFIX := $(patsubst /%,%,$(PREFIX))

.PHONY: all
all: $(PACKAGE_DIR)

$(BUILD_DIR) $(CACHE_DIR):
	mkdir -p $@

.PRECIOUS: $(TARBALL)
$(TARBALL): | $(CACHE_DIR)
	wget -N -c --progress=dot:binary $(SOURCE_URL) -P $(CACHE_DIR)

$(SOURCE_DIR): $(TARBALL) | $(CACHE_DIR)
	tar xf $< -C $(CACHE_DIR)

$(SOURCE_DIR)/Makefile: | $(SOURCE_DIR)
	cd $(SOURCE_DIR) && cmake -DCMAKE_BUILD_TYPE=release .

$(SOURCE_DIR)/src/task: $(SOURCE_DIR)/Makefile
	$(MAKE) -C $(SOURCE_DIR)

$(BUILD_DIR)/usr/local/bin/task: | $(SOURCE_DIR)/src/task
	$(MAKE) -C $(SOURCE_DIR) install DESTDIR=$(BUILD_DIR)

$(PACKAGE_DIR): $(BUILD_DIR)/usr/local/bin/task
	$(eval roots = $(shell cd $(BUILD_DIR) && find $(RELATIVE_PREFIX) -mindepth 1 -maxdepth 1))
	mkdir -p $@
	cd $@ && fpm -s dir -t $(PACKAGE_TYPE) -C $(BUILD_DIR) --force \
		--name $(NAME) --version $(VERSION) --iteration $(ITERATION) \
		--license "$(LICENSE)" --url $(PACKAGE_URL) --description "$(PACKAGE_DESCRIPTION)" \
		$(roots) || cd .. && rm -rf $@

.PHONY: clean distclean
clean:
	rm -rf $(BUILD_DIR) $(CACHE_DIR)

distclean: clean
	rm -rf $(PACKAGE_DIR)
