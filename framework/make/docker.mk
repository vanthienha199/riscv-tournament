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
BASE_MOUNT_DIR = /home/ubuntu
MOUNT_DIR = $(BASE_MOUNT_DIR)/core

MOUNT_BUILD_DIR=BUILD_DIR
MOUNT_FILE_DIR=FILE_DIR

UID := $(shell id -u)
DOCKER_RUN ?= $(DOCKER) run -u $(UID) -v ./:$(MOUNT_DIR) -v $(MOUNT_BUILD_DIR):$(BASE_MOUNT_DIR)/build -v $(MOUNT_FILE_DIR):$(BASE_MOUNT_DIR)/files $(DOCKER_IMAGE)