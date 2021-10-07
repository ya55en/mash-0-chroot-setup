# ma'shmallow chroot test environments Makefile

# You MUST create a `.env.mk` file out of `.env.mk.sample` before using
# make here!  You do that via `./scripts/create-dot-env.sh > .env.mk`.
# Refer to `.env.sample` header comment for details.
#
# If you do not have the proper `.env.mk` , an error pops up and make stops:
#
#   Makefile: .env: No such file or directory
#   make: *** No rule to make target '.env'.  Stop.

include .env.mk
export

SRC_DIR := ../src
TEST_DIR := ../test
SYNC_MASH := sync-mash  # timestamp-only file


#: Ensure a properly mounted chroot (20 < rc < 30) or exit with error.
_ensure_chroot:
	@./4make/chroot-status.sh > /dev/null && rc=$$? || rc=$$? \
	;if [ "$$rc" -gt 20 -a "$$rc" -lt 30 ]; then \
		exit 0 \
	;fi \
	;if [ "$$rc" -eq 0 ]; then \
		./4make/chroot-status.sh || true \
		;rc=7 \
	;else \
		echo 'IMPROPERLY mounted chroot found! Check status.' \
		;./4make/chroot-status.sh || true \
	;fi \
	;exit $$rc


#: Ensure no chroot directory is mounted (rc=0) or exit with error.
_ensure_no_chroot:
	@if ! ./4make/chroot-status.sh > /dev/null; then \
		echo 'There is an ACTIVE chroot - check status.' \
		;./4make/chroot-status.sh \
		;exit 8 \
	;fi


#: Mount special paths into the soon-to-be-chrooted fs tree
mount-chroot:  _ensure_no_chroot
	./mount-chroot.sh


#: Umount all chroot-mounted points, removing any possible processes running
#: in the chroot (mash uid is defined in `.env`).
umount-chroot:  _ensure_chroot
	@for pid in $$(ps axu | awk '/^$(MASH_UID)/ {print $$2}'); do \
		echo "Killing PID $$pid"; sudo kill $$pid \
	;done
	./umount-chroot.sh


#: Prepare a mount point with proper ownership and permissoins
prep-chroot-dir:  _ensure_no_chroot
	@# (First statement would fail if CHROOT directory is not empty.)
	[ -e "$(CHROOT)" ] && sudo rmdir "$(CHROOT)" || true
	sudo mkdir -p "$(CHROOT)"
	sudo chown root:root "$(CHROOT)" && sudo chmod 775 "$(CHROOT)"
	echo "$(CHROOT) created and set."


chroot-down:  _ensure_chroot
	make sync-downloads
	make umount-chroot


$(FOCAL_HEADLESS_TAR).$(TAR_EXT):  export TARGET_NAME := headless
$(FOCAL_HEADLESS_TAR).$(TAR_EXT):  export TAR_FILE = $(TAR_FILE_TEMPLATE)
$(FOCAL_HEADLESS_TAR).$(TAR_EXT):
	./4make/ensure-free-mem.sh 2G
	make prep-chroot-dir
	sudo mount -t tmpfs -o size=1G mash-ramdisk "${CHROOT}"
	./4make/build-tarball.sh $(TARGET_NAME)
	sudo umount $(CHROOT)

# .PHONY:  $(FOCAL_HEADLESS_TAR).$(TAR_EXT)  # FIXME: remove

$(MATE_DESKTOP_TAR).$(TAR_EXT):  export TARGET_NAME := mate-desktop
$(MATE_DESKTOP_TAR).$(TAR_EXT):  export TAR_FILE = $(TAR_FILE_TEMPLATE)
$(MATE_DESKTOP_TAR).$(TAR_EXT):  $(FOCAL_HEADLESS_TAR).$(TAR_EXT)
	./4make/ensure-free-mem.sh 3G
	make prep-chroot-dir
	sudo mount -t tmpfs -o size=2G mash-ramdisk "${CHROOT}"
	./4make/build-tarball.sh $(TARGET_NAME)
	sudo umount $(CHROOT)


headless-up: $(FOCAL_HEADLESS_TAR).$(TAR_EXT)
	./4make/ensure-free-mem.sh 3G
	make prep-chroot-dir
	sudo mount -t tmpfs -o size=2G mash-ramdisk "${CHROOT}"
	sudo tar -xf "$(FOCAL_HEADLESS_TAR).$(TAR_EXT)" -C "$(CHROOT)"
	./mount-chroot.sh
	./4make/copy-mash-in-chroot.sh
	make sync-downloads
	@printf 'Now do something in the chroot ;)  e.g.\n\n $$ sudo chroot $(CHROOT) bash\n\n'


headless-down:  chroot-down


mate-desktop-up:  $(MATE_DESKTOP_TAR).$(TAR_EXT)  prep-chroot-dir
	echo "TAR_FILE=$(TAR_FILE)"
	./4make/ensure-free-mem.sh 8G
	make prep-chroot-dir
	sudo mount -t tmpfs -o size=6G mash-ramdisk "${CHROOT}"
	sudo tar -xzf "$(MATE_DESKTOP_TAR).$(TAR_EXT)" -C "$(CHROOT)"
	./mount-chroot.sh
	./4make/copy-mash-in-chroot.sh
	make sync-downloads
	sudo chroot "$(CHROOT)" start-vnc.sh
	@printf 'Now do something in the chroot ;)  e.g.\n\n $$ sudo chroot $(CHROOT) bash\n\n'


mate-desktop-down:  _ensure_chroot
	@./4make/chroot-status.sh > /dev/null \
	;if [ "$$?" != 22 ]; then \
		"echo NOT found fully mounted *mate* chroot (rc=$?) - check chroot status" \
		;exit 7 \
	;fi
	make sync-downloads
	sudo chroot "$(CHROOT)" stop-vnc.sh
	make chroot-down


EXCLUDED := install.sh
CHROOT_LOCAL := $(CHROOT)/home/mash/.local
RSYNC_OPTS := -rlptDv
RSYNC_OPTS_4SYNC_MASH := -rlptDv --del --exclude=$(EXCLUDED)


#: Sync local workspace mash code with the one installed in the chroot environment.
#: (This one is .PHONY - always executed, unconditionally.)
sync-mash:  _ensure_chroot
	@sudo rsync $(RSYNC_OPTS_4SYNC_MASH) "$(SRC_DIR)/" "$(CHROOT_LOCAL)/opt/mash/"
	@sudo rsync $(RSYNC_OPTS_4SYNC_MASH) "$(TEST_DIR)/" "$(CHROOT)/home/$(MASH_USER)/test/"
	@sudo cp -p "$(SRC_DIR)/install.sh" "$(CHROOT)/home/$(MASH_USER)/install.sh"
	@sudo chown "$(MASH_UID):$(MASH_UID)" \
		"$(CHROOT_LOCAL)/opt/mash/" \
		"$(CHROOT)/home/$(MASH_USER)/test/" \
		"$(CHROOT)/home/$(MASH_USER)/install.sh"


#: Send new downloads to the chroot environment (if one is active) AND
#: do the same in reverse, only adding files (no deletion).
sync-downloads: CHROOT_DOWNLOAD_DIR = $(CHROOT)/home/$(MASH_USER)/.cache/mash/downloads
sync-downloads:  _ensure_chroot
	mkdir -p "$(DOWNLOAD_DIR)"
	sudo mkdir -p "$(CHROOT_DOWNLOAD_DIR)"
	sudo chown "$(MASH_UID):$(MASH_UID)" "$(CHROOT_DOWNLOAD_DIR)"
	sudo rsync "$(RSYNC_OPTS)" "$(DOWNLOAD_DIR)/" "$(CHROOT_DOWNLOAD_DIR)/"
	sudo rsync "$(RSYNC_OPTS)" "$(CHROOT_DOWNLOAD_DIR)/" "$(DOWNLOAD_DIR)/"
	sudo chown -R "$(MASH_UID):$(MASH_UID)" "$(CHROOT_DOWNLOAD_DIR)"
	sudo chown -R "$(USER):$(USER)" "$(DOWNLOAD_DIR)/"


test-%:  _ensure_chroot
	@case "$*" in \
		quick | standard | full) ;; \
		*)  echo "Unknown test level: '$*'"; exit 11 ;; \
	esac
	@echo "running test level '$*'"
	sudo chroot $(CHROOT) sudo -u mash /home/$(MASH_USER)/run-tests.sh "$*"


clean-build:
	rm -rf $(BUILD_DIR); mkdir -p $(BUILD_DIR)


clean-downloads:
	rm -rf $(DOWNLOAD_DIR); mkdir -p $(DOWNLOAD_DIR)


clean:  clean-build


clean-all: clean-build clean-downloads


#: Dump chroot status and return a crafted rc (see the script [1] for detials).
#: [1] ./4make/chroot-status.sh
status:
	@./4make/chroot-status.sh && echo "(rc=$$?)" || echo "(rc=$$?)"


.PHONY:  _ensure_chroot _ensure_no_chroot mount-chroot umount-chroot prep-chroot-dir chroot-down
.PHONY:  clean-build clean-downloads clean-all clean
.PHONY:  headless-up headless-down mate-desktop-up mate-desktop-down
.PHONY:  test
.PHONY:  sync-mash sync-downloads status
