                include stdapp.def
		include product.def
		include geode.def
		include system.def
		include Internal/fileInt.def
		include Internal/dos.def

                SetGeosConvention               ; set calling convention

ASM_TEXT        segment public 'CODE'

	global FASTFILEMOVE:far
FASTFILEMOVE	proc	far	srcPtr:fptr, destPtr:fptr
		uses	es, di, ds, si
		.enter
		lds	dx, srcPtr
		les	di, destPtr
		mov	ax, MSDOS_RENAME_FILE or 7100h  ; longname version
		call	SysLockBIOS
		call	FileInt21
		call	SysUnlockBIOS
		jc	done
		clr	ax
done:
		.leave
		ret
FASTFILEMOVE	endp

mslfName	char	"mslf    ifsd"

	global CHECKFASTFILEMOVE:far
CHECKFASTFILEMOVE	proc	far
		uses	es, di
		.enter
		segmov	es, cs, di
		mov	di, offset mslfName
		mov	ax, GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE
		mov	cx, mask GA_DRIVER
		clr	dx
		call	GeodeFind
		mov	ax, -1			; found, can use FastFileMove
		jc	done
		mov	ax, 0			; not found
done:
		.leave
		ret
CHECKFASTFILEMOVE	endp

ASM_TEXT        ends


