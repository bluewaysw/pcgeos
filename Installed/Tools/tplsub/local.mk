##############################################################################
#
# PROJECT:	PC GEOS
# MODULE:	tplsub -- local overrides
# FILE: 	local.mk
#
# DESCRIPTION:
#	Build tplsub as a DOS-only tool from Installed/Tools flow.
#
###############################################################################

.MAIN		: all

DOS_DIR		= dos.md
DOS_EXE		= $(DOS_DIR)/tplsub.exe
DOS_OBJ		= $(DOS_DIR)/tplsub.obj
DOS_ERR		= $(DOS_DIR)/tplsub.err
SRC_FILE	= $(ROOT_DIR)/Tools/tplsub/tplsub.c
DEST_FILE	= $(ROOT_DIR)/bin/tplsub.exe

all		: $(DOS_EXE)
linux		: all
win32		:
depend		:

install		: installlinux

installlinux	: $(DOS_EXE)
#if defined(linux)
	cp $(DOS_EXE) $(DEST_FILE)
#else
	copy /Y $(DOS_EXE:S/\//\\/g) $(DEST_FILE:S/\//\\/g)
#endif

installwin32	:
	@echo tplsub is DOS-only, skipping win32 build

$(DOS_EXE)	: $(SRC_FILE)
#if defined(linux)
	mkdir -p $(DOS_DIR) ; \
	cd $(DOS_DIR) ; \
	wcl -bt=dos -0 -ms -os -i=$(WATCOM)/h -fe=tplsub.exe $(SRC_FILE)
#else
	if not exist $(DOS_DIR:S/\//\\/g) mkdir $(DOS_DIR:S/\//\\/g)
	cd $(DOS_DIR:S/\//\\/g) & wcl -bt=dos -0 -ms -os -i=$(WATCOM)\\h -fe=tplsub.exe $(SRC_FILE:S/\//\\/g)
#endif
