
#if defined(linux)
MK_MAKE = mkdir -p $PARAM ; \
		cd $PARAM ; \
		$(MAKE) -k -I$PARAM
#else
MK_MAKE = mkdir %PARAM% & \
		cd %PARAM% & \
		$(MAKE) -k -I%PARAM%
#endif


BINS = Tools/esp Tools/uicpp Tools/goc Tools/grev Tools/loc Tools/nmkmf Tools/pmake/makedpnd \
		Tools/glue Tools/uic Tools/pmake/findlbdr 
# Tools/geodump Tools/sym2dis Tools/ldf2sls
LIBS = Tools/utils Tools/compat

install		: $(LIBS) $(BINS)

$(LIBS) : 
#if defined(linux)
	mkdir -p $(ROOT_DIR)/Installed/$(.TARGET) ; \
	cd $(ROOT_DIR)/Installed/$(.TARGET) ; \
	$(MAKE) -k -I$(ROOT_DIR)/Installed/$(.TARGET) all
#else
	mkdir $(ROOT_DIR)\Installed\$(.TARGET:S/\//\\/g) & \
	cd $(ROOT_DIR)\Installed\$(.TARGET:S/\//\\/g) & \
	$(MAKE) -k -I$(ROOT_DIR)\Installed\$(.TARGET:S/\//\\/g) all
#endif

$(BINS) : $(LIBS)
#if defined(linux)
	mkdir -p $(ROOT_DIR)/Installed/$(.TARGET) ; \
	cd $(ROOT_DIR)/Installed/$(.TARGET) ; \
	$(MAKE) -k -I$(ROOT_DIR)/Installed/$(.TARGET) installlinux ; \
	$(MAKE) -k -I$(ROOT_DIR)/Installed/$(.TARGET) installwin32
#else
	mkdir $(ROOT_DIR)\Installed\$(.TARGET:S/\//\\/g) & \
	cd $(ROOT_DIR)\Installed\$(.TARGET:S/\//\\/g) & \
	$(MAKE) -k -I$(ROOT_DIR)\Installed\$(.TARGET:S/\//\\/g) install
#endif

