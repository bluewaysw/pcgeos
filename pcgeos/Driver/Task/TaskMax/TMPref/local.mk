# $Id: local.mk,v 1.1 97/04/18 11:58:05 newdeal Exp $
GSUFF		= vm
#
#	-i  	specifies geode from which to get the imported library table
#	-N  	sets the copyright notice. We store the longname of the driver
#		for which this thing is the preferences tree.
#	-t  	sets the token. Prefts looks for VMPD
#
LINKFLAGS	+= -i $(ROOT_DIR)/Installed/Appl/Preferences/PrefMgr/prefmgr.geo -N "TaskMax Task Driver" -t "VMPD" -l "TaskMAX Preferences"
PROTOCONST	= PREFVM_DOC
NO_EC		=  

#include    <$(SYSMAKEFILE)>
