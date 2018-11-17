#include <$(SYSMAKEFILE)>

# Set Copyright notice
LINKFLAGS       += -N by\20Marcus\20Groeber

# compile user interface metafile into GOC include file
# won't work in non SDK environment (with \installed)
# just do it manually once - jfh
# fontm\font_ui.goh: fontm\font_ui.pvg
#	pmvg $(.ALLSRC) $(.TARGET)
