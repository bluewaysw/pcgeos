#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = bbxmail
ASMCODE         = asmcodeManager.asm stylesStyles.asm parseTimezone.asm\
                  stylesStack.asm stylesStyles.def
UI              = uiStrings.goc uiIcons.goc uiMain.goc
MAIN            = mainPrimary.goc mainUtils.goc mainMisc.goc\
                  mainProcess.goc mainApp.goc mainAddr.goc
MAIL            = mailPrint.goc mailUIDL.goc mailList.goc mailAtt.goc\
                  mailComp.goc mailSendReceive.goc mailFile.goc styles.goc\
                  mailSearch.goc mailRead.goc
FOLDER          = folderMessage.goc folderList.goc folderRenameClass.goc\
                  folderMove.goc folderAccount.goc
UI_TO_RDFS      =
OBJS            = uiStrings.obj uiIcons.obj uiMain.obj mainPrimary.obj\
                  mainUtils.obj mainMisc.obj mainProcess.obj mainApp.obj\
                  mainAddr.obj mailPrint.obj mailUIDL.obj mailList.obj\
                  mailAtt.obj mailComp.obj mailSendReceive.obj mailFile.obj\
                  styles.obj mailSearch.obj mailRead.obj folderMessage.obj\
                  folderList.obj folderRenameClass.obj folderMove.obj\
                  folderAccount.obj
COMMON          = class.goh mail.goh global.goh dex.goh
MODULES         = asmcode
CMODULES        = ui main mail folder
SRCS            = $(ASMCODE) $(UI) $(MAIN) $(MAIL) $(FOLDER) $(COMMON)
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
