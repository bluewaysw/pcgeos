# $Id: local.mk,v 1.1 97/04/04 16:48:40 newdeal Exp $
GSUFF		= vm
#
#	-i  	specifies geode from which to get the imported library table
#	    	for object relocations (the installed Preferences)
#	-N  	sets the copyright notice. We store the longname of the saver
#		for which this thing is the preferences tree.
#	-t  	sets the token, just because.
#
LINKFLAGS	+= -i $(ROOT_DIR)/Installed/Appl/Preferences/PrefMgr/prefmgr.geo -N "Pith & Moan" -t "VMPD" -l "Pith & Moan Options"
#
# Set the protocol number for the file so PrefContainer is willing to use it.
#
PROTOCONST	= PREFVM_DOC
#
# We have no error-checking version
#
NO_EC		=  
#
# Get rid of the LIBOBJ variable, as we create no .ldf file...
#
#undef LIBOBJ

#include    <$(SYSMAKEFILE)>
