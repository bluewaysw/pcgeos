all             : gsetup
full            : gsetup
install         : gsetup
installlinux    : gsetup
installwin32    : gsetup
depend          :

gsetup : $(ROOT_DIR)/Tools/gsetup/gsetup.c MAKETOOL

MAKETOOL : .USE
#if defined(linux)
	wcl -bt=dos -ms -zq -i="$(WATCOM)/h" \
		-fe="$(ROOT_DIR)/Tools/build/product/bbxensem/gsetup/gsetup.exe" \
		"$(.ALLSRC)"
#else
	wcl -bt=dos -ms -zq -i="$(WATCOM)\h" \
		-fe="$(ROOT_DIR:S/\//\\/g)\Tools\build\product\bbxensem\gsetup\gsetup.exe" \
		"$(.ALLSRC:S/\//\\/g)"
#endif
