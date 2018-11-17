#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = GPCMail
ASMTOOLS        = asmtoolsManager.asm
FOLDER          = folderAccount.goc folderList.goc folderMessage.goc\
                  folderMove.goc folderRenameClass.goc
MAIL            = mailAdvertisement.goc mailAttach.goc mailComposer.goc\
                  mailFile.goc mailImport.goc mailList.goc mailPrint.goc\
                  mailRead.goc mailSearch.goc mailSendReceive.goc\
                  mailStyles.goc mailUIDL.goc
MAIN            = mainAddress.goc mainApp.goc mainPrimary.goc\
                  mainProcess.goc mainShowTool.goc mainUtils.goc
STYLES          = parseTimezone.asm stylesManager.asm stylesStack.asm\
                  stylesStyles.asm stylesStyles.def
UI              = uiIcons.goc uiMain.goc uiStrings.goc
UI_TO_RDFS      =
OBJS            = folderAccount.obj folderList.obj folderMessage.obj\
                  folderMove.obj folderRenameClass.obj\
                  mailAdvertisement.obj mailAttach.obj mailComposer.obj\
                  mailFile.obj mailImport.obj mailList.obj mailPrint.obj\
                  mailRead.obj mailSearch.obj mailSendReceive.obj\
                  mailStyles.obj mailUIDL.obj mainAddress.obj mainApp.obj\
                  mainPrimary.obj mainProcess.obj mainShowTool.obj\
                  mainUtils.obj uiIcons.obj uiMain.obj uiStrings.obj
COMMON          = class.goh dex.goh global.goh mail.goh
MODULES         = ASMTOOLS Styles
CMODULES        = Folder Mail Main UI
SRCS            = $(ASMTOOLS) $(FOLDER) $(MAIL) $(MAIN) $(STYLES) $(UI)\
                  $(COMMON)
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
