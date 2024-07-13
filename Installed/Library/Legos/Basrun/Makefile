#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = basrun
BASRUN          = basrunManager.asm heapint.def bugmain.c builtin.c debug.c\
                  ehan.c fidoutil.c funtab.c math.c prog.c rpc.c runec.c\
                  runheap.c runmain.c runmain2.c runmath.c runrout.c\
                  runtask.c sst.c strmap.c unload.c bugext.h bugint.h\
                  builtin.h compat.h computil.h ehan.h ehanint.h faterr.h\
                  fixds.h funtab.h mymath.h mystdapp.h profile.h prog.h\
                  rheapint.h run.h runint.h runmath.h sst.h stack.h\
                  strmap.h unload.h comp.goc computil.goc interp.goc\
                  runerr.goc
FIDOENUM        = eagg.asm emain.asm etable.asm fidoenumManager.asm
FIDOMAIN        = fidomainManager.asm mentry.asm mgeode.asm mmodule.asm\
                  mtask.asm
UI_TO_RDFS      =
OBJS            = bugmain.obj builtin.obj debug.obj ehan.obj fidoutil.obj\
                  funtab.obj math.obj prog.obj rpc.obj runec.obj\
                  runheap.obj runmain.obj runmain2.obj runmath.obj\
                  runrout.obj runtask.obj sst.obj strmap.obj unload.obj\
                  comp.obj computil.obj interp.obj runerr.obj
COMMON          = fidoint.def fidoint.h fidostr.def
MODULES         = Basrun Fidoenum Fidomain
CMODULES        = Basrun
SRCS            = $(BASRUN) $(FIDOENUM) $(FIDOMAIN) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = basrun

SYSMAKEFILE     = geode.mk

#include <geos.mk>
#include <gpath.mk>

#if exists(local.mk)
#include "local.mk"
#else
#include <$(SYSMAKEFILE)>
#endif

#if exists($(DEPFILE))
#include "$(DEPFILE)"
#endif
