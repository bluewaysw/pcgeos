dir /staff/pcgeos/Tools/swat/tcl
dir /staff/pcgeos/Tools/swat/curses
dir /staff/pcgeos/Tools/swat/x11
dir /staff/pcgeos/Tools/swat
dir /staff/pcgeos/adam/Tools/swat/tcl
#dir /staff/pcgeos/adam/Tools/swat/curses
dir /staff/pcgeos/adam/Tools/swat/x11
define rs
	run -D
end
document rs
	runs swat in my environment
end
#define dbgrpc
#	break main
#	commands 0
#		set rpcDebug=1,rpcNoTimeout=1
#		cont
#	end
#end
#define dbgsyminsert
#	break SymInsertSym
#	commands 0
#		echo Entering SymInsertSym. Tree is:\n
#		set SymPrintTree(*rootPtr, 0)
#	end
#end
#document dbgsyminsert
#Cause the root of the tree to be printed on each call to SymInsertSym
#end

#define dbgheap
#break main
#commands 0
#set debug_level=2
#cont
# end
#end
#document dbgheap
#Turn on massive debugging of malloc on entry to malloc
#end

cd /staff/pcgeos/jim/Library/Kernel
handle 4 nopass
handle 2 pass nostop noprint
handle 3 stop nopass

define s2
signal 2
end

define rpcc
set Rpc_Send(17)
end

break error
set screensize 0

define psym
set $file=(VMHandle)(($sym)->data[0])
set $block=(VMBlockHandle)(((long)($sym)->data[1]>>16)&0xffff)
set $offset=(word)((long)($sym)->data[1]&0xffff)
set $os=(ObjSym *)(memHandleTable[((VMBlock *)((char *)(((VMFilePtr)$file)->blkHdr)+$block))->VMB_used.VMBU_memHandle].addr+$offset)
print (char *)memHandleTable[((VMBlock *)((char *)(((VMFilePtr)$file)->blkHdr)+(($os->name>>16)&0xffff)))->VMB_used.VMBU_memHandle].addr+($os->name&0xffff)
print *$os
end

define pid
print (char *)memHandleTable[((VMBlock *)((char *)(((VMFilePtr)*$idfile)->blkHdr)+(($id>>16)&0xffff)))->VMB_used.VMBU_memHandle].addr+($id&0xffff)
end
define pvm
print *((VMBlock *)((char *)(((VMFilePtr)*$idfile)->blkHdr)+$vm))
end

break XtError
set environment TERM xterm
unset environment TERMCAP
