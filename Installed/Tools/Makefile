
MK_SET = 
MK_MAKE = mkdir -p $PARAM ; \
		cd $PARAM ; \
		$(MAKE) -k -I$PARAM



install		: binEsp binUicpp binGoc binGrev binLoc binMkmf \
		  binMakedpnd binGlue binUic binFindlbdr

libUtils	:	
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/utils ; \
	$(MK_MAKE) all

libCompat	:	
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/compat ; \
	$(MK_MAKE) all

binEsp	:	libUtils libCompat
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/esp ; \
	$(MK_MAKE) install

binUicpp	: 	utils compat
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/uicpp ; \
	$(MK_MAKE) install

binGoc	:	libUtils libCompat
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/goc ; \
	$(MK_MAKE) installlinux ;\
	$(MK_MAKE) installwin32

binGrev	:	libCompat
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/grev ; \
	$(MK_MAKE) install

binLoc	:	libUtils libCompat
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/loc ; \
	$(MK_MAKE) install

binMkmf	:	libUtils libCompat
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/nmkmf ; \
	$(MK_MAKE) installlinux ; \
	$(MK_MAKE) installwin32

binMakedpnd	:	libCompat
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/pmake/makedpnd ; \
	$(MK_MAKE) installlinux ; \
	$(MK_MAKE) installwin32

binGlue	:	libUtils libCompat
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/glue ; \
	$(MK_MAKE) install
	
binUic	:	libUtils libCompat
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/uic ; \
	$(MK_MAKE) installlinux ; \
	$(MK_MAKE) installwin32

binFindlbdr	:	libUtils libCompat
	$(MK_SET) PARAM=$(ROOT_DIR)/Installed/Tools/pmake/findlbdr ; \
	$(MK_MAKE) install
	
	
	
