##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- autoloaded function definitions
# FILE: 	autoload.tcl
# AUTHOR: 	Adam de Boor, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Things to be autoloaded
#
#	$Id: autoload.tcl,v 3.25 90/11/16 11:20:38 tony Exp $
#
###############################################################################
[autoload smatch 1 smatch]
[autoload whatat 1 whatat]
[autoload ps 1 ps]
[autoload int 1 int]
[autoload intr 1 int]
[autoload wakeup-thread 1 process]
[autoload wakeup 0 process]
[autoload spawn 0 process]
[autoload print 0 print]
[autoload prenum 1 print]
[autoload precord 1 print]
[autoload call 1 call]
[autoload call-patient 1 call]
[autoload exit 1 call]
[autoload gloss 1 gloss]
[autoload ref 1 gloss]
[autoload xref 1 gloss]
[autoload showcalls 1 showcalls]
[autoload dcall 1 dcall]
[autoload help 0 help]
[autoload cycles 1 timing]
[autoload vi 1 unix]
[autoload ls 1 unix]
[autoload pmake 1 unix]
[autoload vif 1 unix]
[autoload patch 1 patch]
[autoload patchout 1 patch]
[autoload patchin 1 patch]
[autoload setcc 1 setcc]
[autoload hbrk 1 hbrk]
[autoload ewatch 0 emacs]
[autoload emacs 0 emacs]
[autoload slist 0 srclist]
[autoload tbrk 0 tbrk]
[autoload print-cur-regs 1 curregs]

##############################################################################
#                                                                            #
#   	    	    	    KERNEL PLAYTHINGS				     #
#									     #
##############################################################################
[autoload hwalk 1 heap]
[autoload memsize 1 heap]
[autoload hgwalk 1 heap]
[autoload handles 1 heap]
[autoload phandle 0 heap]
[autoload fwalk 1 filehandle]
[autoload fhandle 0 filehandle]
[autoload tmem 1 heap]
[autoload elist 1 event]
[autoload map-method 1 object]
[autoload threadstat 1 thread]
[autoload freeze 1 thread]
[autoload thaw 1 thread]
[autoload pthread 0 thread]
[autoload sysfiles 1 dos]
[autoload geosfiles 1 dos]
[autoload preg 1 region]
[autoload wintree 0 wintree]
[autoload lhwalk 1 lm]
[autoload ec 0 ec]
[autoload pvmt 1 vm]
[autoload pvmb 1 vm]
[autoload prdb 1 vm]
[autoload dbwatch 0 dbwatch]
[autoload loadgeode 1 gload]
[autoload loadapp 1 gload]
[autoload kbdperf 1 uiperf]
[autoload waitpostinfo 0 dos]
[autoload twalk 0 timer]
[autoload sbwalk 0 timer]
##############################################################################
#                                                                            #
#   	    	    	    UI PLAYTHINGS				     #
#									     #
##############################################################################
[autoload pobject 0 pobject]
[autoload pvm 1 pvm]
[autoload pgs 1 pvm]
[autoload phint 1 phint]
[autoload objtree 1 user]
[autoload vistree 1 objtree]
[autoload gentree 1 objtree]
[autoload impvistree 1 objtree]
[autoload impgentree 1 objtree]
[autoload vup 1 objtree]
[autoload gup 1 objtree]
[autoload pclass 0 objtree]
[autoload objwalk 1 lm]
[autoload systemobj 1 user]
[autoload flowobj 1 user]
[autoload impliedwin 1 user]
[autoload impliedgrab 1 user]
[autoload prgen 0 user]
[autoload prvis 0 user]
[autoload prspec 0 user]
[autoload prinst 1 user]
[autoload prsize 1 user]
#[autoload screenwin 1 user]
#[autoload fieldwin 1 user]
[autoload objwatch 0 objwatch]
[autoload objbrk 0 objwatch]
[autoload mwatch 1 objwatch]
[autoload pod 1 objwatch]
[autoload obj-foreach-class 1 object]
[autoload print-obj-and-method 1 object]
[autoload get-chunk-addr-from-obj-addr 1 object]
[autoload obj-name 1 object]
[autoload next-master 1 object]
[autoload fetch-optr 1 object]
[autoload obj-class 1 object]
[autoload obj-prof 1 objprof]

##############################################################################
#                                                                            #
#   	    	    	    OTHER PLAYTHINGS				     #
#									     #
##############################################################################
[autoload ptext 1 ptext]
[autoload fonts 1 font]
[autoload psize 1 putils]
[autoload pluralize 1 putils]
[autoload size 1 putils]
[autoload videolog 1 video]
