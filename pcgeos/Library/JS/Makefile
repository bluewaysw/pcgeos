#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = JS
ASMTOOLS        = asmtoolsManager.asm malloc.asm
SRCCORE         = analyze.c atexit.c brktest.c call.c code.c codeprt2.c\
                  define.c expressn.c extlib.c function.c garbage.c\
                  interprt.c jsedll.c jseengin.c jselib.c library.c\
                  loclfunc.c operator.c secode.c security.c source.c\
                  statemnt.c textcore.c token.c util.c var.c varutil.c
SRCLIB          = ecmamisc.c mathobj.c sebuffer.c seconvrt.c sedate.c\
                  seecma.c seliball.c selibutl.c seobject.c setxtlib.c
SRCMISC         = dbgprntf.c dirparts.c globldat.c jsemem.c memext.c\
                  seobjfun.c utilhuge.c utilstr.c malloc.h
UI_TO_RDFS      =
OBJS            = analyze.obj atexit.obj brktest.obj call.obj code.obj\
                  codeprt2.obj define.obj expressn.obj extlib.obj\
                  function.obj garbage.obj interprt.obj jsedll.obj\
                  jseengin.obj jselib.obj library.obj loclfunc.obj\
                  operator.obj secode.obj security.obj source.obj\
                  statemnt.obj textcore.obj token.obj util.obj var.obj\
                  varutil.obj ecmamisc.obj mathobj.obj sebuffer.obj\
                  seconvrt.obj sedate.obj seecma.obj seliball.obj\
                  selibutl.obj seobject.obj setxtlib.obj dbgprntf.obj\
                  dirparts.obj globldat.obj jsemem.obj memext.obj\
                  seobjfun.obj utilhuge.obj utilstr.obj
COMMON          =
MODULES         = asmtools
CMODULES        = srccore srclib srcmisc
SRCS            = $(ASMTOOLS) $(SRCCORE) $(SRCLIB) $(SRCMISC) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = js

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
