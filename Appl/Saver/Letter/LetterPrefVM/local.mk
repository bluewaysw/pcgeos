# $Id: local.mk,v 1.1 97/04/04 16:45:31 newdeal Exp $

#
#	-i  	specifies geode from which to get the imported library table
#	    	for object relocations (the installed Preferences)
#	-N  	sets the copyright notice. We store the longname of the saver
#		for which this thing is the preferences tree.
#	-t  	sets the token, just because.
#
LINKFLAGS	+= -N "Typographer's Nightmare"
#
# Set the protocol number for the file so PrefContainer is willing to use it.
#
PROTOCONST	= PREF_MODULE

#
# We have no error-checking version
#
NO_EC		=  

#include    <$(SYSMAKEFILE)>
