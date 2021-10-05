# ma'shmallow chroot test environments Makefile

# You MUST copy `.env.sample` into `.env` before using make here!
# Otherwise, an error pops up and make stops:
#   Makefile: .env: No such file or directory
#   make: *** No rule to make target '.env'.  Stop.

include .env
export


#: Umount all chroot-mounted points, removing any possible processes running
#: in the chroot (mash uid is defined in `.env`).
umount-chroot:
	@for pid in $$(ps axu | awk '/^$(MASH_UID)/ {print $$2}'); do \
		echo "Killing PID $$pid" \
		;sudo kill $$pid \
	;done
	@if mount | grep -q "$(CHROOT)"; then ./umount-chroot.sh; fi


#: Prepare a mount point with proper ownership and permissoins
prep-chroot-dir:  umount-chroot
	@if [ -e "$(CHROOT)" ]; then sudo rmdir "$(CHROOT)"; fi
	@sudo mkdir -p "$(CHROOT)"
	@sudo chown root:root "$(CHROOT)" && sudo chmod 775 "$(CHROOT)"


#: Mount special paths into the soon-to-be-chrooted fs tree
mount-chroot:  prep-chroot-dir
	./mount-chroot.sh


chroot-down:  umount-chroot


$(FOCAL_HEADLESS_TAR):  prep-chroot-dir
	@if [ -e "$(FOCAL_HEADLESS_TAR)" ]; then \
		echo "$(FOCAL_HEADLESS_TAR) is up-to-date." \
	;else \
		./4make/build-tarball.sh headless \
	;fi


$(MATE_DESKTOP_TAR):  $(FOCAL_HEADLESS_TAR)  prep-chroot-dir
	@if [ -e "$(MATE_DESKTOP_TAR)" ]; then \
		echo "$(MATE_DESKTOP_TAR) is up-to-date." \
	;else \
		./4make/build-tarball.sh mate-desktop \
	;fi


clean-tarballs:
	@for file in $(BUILD_DIR)/*gz; do \
		echo "Removing $$file..." \
		;rm -f "$$file" \
	;done


clean:  clean-tarballs


# .ONESHELL:
headless-on:
	export TARGET_NAME=headless
	echo $(TAR_FILE_TEMPLATE)


.ONESHELL:
headless-up:  $(BUILD_DIR)/focal-headless.tgz  prep-chroot-dir
	TARGET_NAME=headless
	eval "TAR_FILE=$(TAR_FILE_TEMPLATE)"
	./4make/ensure-free-mem.sh 2G
	sudo mount -t tmpfs -o size=1G mash-ramdisk "${CHROOT}"
	sudo tar -xf "$$TAR_FILE" -g /dev/null -C "$(CHROOT)"
	./mount-chroot.sh
	./4make/copy-mash-in-chroot.sh
	echo 'Now do something in the chroot ;)  e.g. sudo chroot $(CHROOT) bash'


headless-down:  chroot-down


.ONESHELL:
mate-desktop-up:  $(BUILD_DIR)/focal-mate-desktop.tgz  prep-chroot-dir
	set -x
	TARGET_NAME=mate-desktop
	eval "TAR_FILE=$(TAR_FILE_TEMPLATE)"
	echo "TAR_FILE=$$TAR_FILE"
	./4make/ensure-free-mem.sh 8G
	sudo mount -t tmpfs -o size=6G mash-ramdisk "${CHROOT}"
	sudo tar -xzf "$(FOCAL_HEADLESS_TAR)" -g /dev/null -C "$(CHROOT)" || true
	sudo tar -xzf "$$TAR_FILE" -g /dev/null -C "$(CHROOT)" || true
	./mount-chroot.sh
	./4make/copy-mash-in-chroot.sh
	set +x
	echo 'Now do something in the chroot ;)  e.g. sudo chroot $(CHROOT) bash'


mate-desktop-down:  chroot-down


.PHONY:  umount-chroot prep-chroot-dir mount-chroot chroot-down
.PHONY:  headless-up headless-down mate-desktop-up mate-desktop-down
.PHONY:  clean-tarballs clean
