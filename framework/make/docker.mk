##################################################################################################################
## Utility for running builds in docker container
##################################################################################################################

DOCKER ?= docker
TEST_DOCKER := $(shell $(DOCKER) --help 2>/dev/null)
check_docker:
ifdef TEST_DOCKER
	@echo "Found docker"
else
	$(error $(RED)Please install docker$(RESET))
endif

UID := $(shell id -u)
DOCKER_RUN ?= $(DOCKER) run -u $(UID) -it -v ./:$(MOUNT_DIR) $(DOCKER_IMAGE)