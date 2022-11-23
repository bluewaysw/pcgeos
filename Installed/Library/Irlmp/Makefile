#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = irlmp
IAS             = iasClientActions.asm iasClientEvents.asm iasCode.asm\
                  iasConfirm.asm iasIrlmp.asm iasManager.asm\
                  iasServerActions.asm iasServerCallback.asm\
                  iasServerEvents.asm iasServerProcess.asm\
                  iasServerSend.asm iasUtils.asm iasVariable.def
IRDB            = irdbApi.asm irdbC.asm irdbGetValueInternal.asm\
                  irdbInternal.asm irdbManager.asm irdbUtils.asm\
                  irdbConstant.def
IRLAPFSM        = irlapfsmActions.asm irlapfsmCode.asm irlapfsmEvents.asm\
                  irlapfsmManager.asm irlapfsmUtils.asm\
                  irlapfsmVariable.def
IRLMP           = irlmpApi.asm irlmpC.asm irlmpCallback.asm irlmpIas.asm\
                  irlmpInitExit.asm irlmpManager.asm irlmpUtils.asm\
                  irlmpVariable.def
ISAP            = isapCallback.asm isapInitExit.asm isapManager.asm\
                  isapRequest.asm isapUtils.asm isapVariable.def
LSAPFSM         = lsapfsmActions.asm lsapfsmCode.asm lsapfsmEvents.asm\
                  lsapfsmManager.asm lsapfsmUtils.asm lsapfsmVariable.def
MAIN            = mainLibrary.asm mainManager.asm mainProcess.asm\
                  mainUtils.asm mainConstant.def mainVariable.def
STATIONFSM      = stationfsmActions.asm stationfsmCode.asm\
                  stationfsmEvents.asm stationfsmManager.asm\
                  stationfsmUtils.asm stationfsmVariable.def
TTP             = ttpApi.asm ttpC.asm ttpCallback.asm ttpManager.asm\
                  ttpQueue.asm ttpUtils.asm
UI              = uiManager.asm uiMain.ui
UTILS           = utilsEC.asm utilsEndpoint.asm utilsManager.asm\
                  utilsPDU.asm utilsSet.asm utilsUtils.asm\
                  utilsVariable.def
UI_TO_RDFS      = uiMain.ui
OBJS            =
COMMON          = irlmpConstant.def irlmpGeode.def irlmpIas.def\
                  irlmpIas.uih irlmpIrdb.def irlmpIrlapFsm.def\
                  irlmpIrlapFsm.uih irlmpIrlmp.def irlmpIsap.def\
                  irlmpLsapFsm.def irlmpMain.def irlmpStationFsm.def\
                  irlmpStationFsm.uih irlmpTinyTP.def irlmpUI.def\
                  irlmpUtils.def
MODULES         = Ias Irdb IrlapFsm Irlmp Isap LsapFsm Main StationFsm Ttp\
                  UI Utils
CMODULES        =
SRCS            = $(IAS) $(IRDB) $(IRLAPFSM) $(IRLMP) $(ISAP) $(LSAPFSM)\
                  $(MAIN) $(STATIONFSM) $(TTP) $(UI) $(UTILS) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = irlmp

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
