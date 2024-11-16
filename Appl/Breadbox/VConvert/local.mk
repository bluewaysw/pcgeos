#include <$(SYSMAKEFILE)>

# Set Copyright notice
LINKFLAGS       += -N Copyright\20Marcus\20Groeber

# compile user interface metafile into GOC include file
#vconv\vconv_ui.goh: vconv\vconv_ui.pvg
#	pmvg $(.ALLSRC) $(.TARGET)

