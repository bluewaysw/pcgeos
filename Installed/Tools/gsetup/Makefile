all             : gsetup
install         : gsetup
installlinux    : gsetup
installwin32    : gsetup
depend          :

gsetup :
#if defined(linux)
	wcl -bt=dos -ms -zq -i="$(WATCOM)/h" \
		-fe="$(ROOT_DIR)/Tools/build/product/bbxensem/Scripts/gsetup.exe" \
		"$(ROOT_DIR)/Tools/gsetup/gsetup.c"
#else
	wcl -bt=dos -ms -zq -i="$(WATCOM)\h" \
		-fe="$(ROOT_DIR:S/\//\\/g)\Tools\build\product\bbxensem\Scripts\gsetup.exe" \
		"$(ROOT_DIR:S/\//\\/g)\Tools\gsetup\gsetup.c"
#endif
