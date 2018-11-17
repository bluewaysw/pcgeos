#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = bbxmail
ASMCODE         = asmcodeManager.asm parseTimezone.asm stylesStack.asm\
                  stylesStyles.asm stylesStyles.def
FOLDER          = folderAccount.goc folderList.goc folderMessage.goc\
                  folderMove.goc folderRenameClass.goc
MAIL            = mailAtt.goc mailComp.goc mailFile.goc mailList.goc\
                  mailPrint.goc mailRead.goc mailSearch.goc\
                  mailSendReceive.goc mailUIDL.goc styles.goc
MAIN            = mainAddr.goc mainApp.goc mainMisc.goc mainPrimary.goc\
                  mainProcess.goc mainUtils.goc
UI              = uiIcons.goc uiMain.goc uiStrings.goc
UI_TO_RDFS      =
OBJS            = folderAccount.obj folderList.obj folderMessage.obj\
                  folderMove.obj folderRenameClass.obj mailAtt.obj\
                  mailComp.obj mailFile.obj mailList.obj mailPrint.obj\
                  mailRead.obj mailSearch.obj mailSendReceive.obj\
                  mailUIDL.obj styles.obj mainAddr.obj mainApp.obj\
                  mainMisc.obj mainPrimary.obj mainProcess.obj\
                  mainUtils.obj uiIcons.obj uiMain.obj uiStrings.obj
COMMON          = class.goh dex.goh global.goh mail.goh
MODULES         = asmcode
CMODULES        = folder mail main ui
SRCS            = $(ASMCODE) $(FOLDER) $(MAIL) $(MAIN) $(UI) $(COMMON)
LOBJS           =

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
