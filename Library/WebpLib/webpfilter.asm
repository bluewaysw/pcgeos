	;
	; VP8 edge filters derived from the C reference in webpcore.inc.
	; See LICENSE.md and PATENTS.md for the SimpleWebP attribution.
	;

		include	stdapp.def
		include	product.def
		SetGeosConvention

if SUPPORT_32BIT_DATA_REGS
.386
endif

WebPDspCode segment public 'CODE'

	;
	; Load one unsigned pixel into AX without changing the buffer segment.
	;
WebPLoadPixel macro
if SUPPORT_32BIT_DATA_REGS
	; ATTENTION: ESP has no MOVZX mnemonic. Replace these bytes when it does.
		.inst	byte	0fh, 0b6h, 05h ; movzx ax, byte ptr ds:[di] (16-bit segment)
else
		clr	ax
		mov	al, ds:[di]
endif
endm

	;
	; Pixel differences are in -255..255, so negation cannot overflow.
	;
WebPAbsAX macro
		local	positive
		tst	ax
		jns	positive
		neg	ax
positive:
endm

	;
	; Preserve signed rounding, including on pre-386 product builds.
	;
WebPShiftAX macro bits
if SUPPORT_32BIT_DATA_REGS
		sar	ax, bits
else
rept bits
		sar	ax, 1
endm
endif
endm

	;
	; Compare the pixel in AX with a saved neighbor in WebPFilterEdge.
	;
WebPInnerCheck macro sample
		sub	ax, sample
		WebPAbsAX
		cmp	ax, innerThresh
		LONG ja	nextSample
endm

	;
	; C entry points: far buffer pointer and word scalar arguments, Pascal.
	; The shared loop receives DS:SI, BX=across, DX=along, CX=count, AX=thresh.
	;
global WEBPFILTERSIMPLE:far
WEBPFILTERSIMPLE proc far pixelsP:fptr, acrossStep:word, alongStep:word,
		count:word, thresh:word
	uses bx, cx, dx, ds, es, si, di
	.enter
		mov	cx, count
		jcxz	done
		lds	si, pixelsP
		mov	bx, acrossStep
		mov	dx, alongStep
		mov	ax, thresh
		clr	di
		push	di		; simple filter, no inner or HEV threshold
		push	di
		push	di
		call	WebPFilterEdge
done:
	.leave
		ret
WEBPFILTERSIMPLE endp

global WEBPFILTER24:far
WEBPFILTER24 proc far pixelsP:fptr, acrossStep:word, alongStep:word,
		count:word, thresh:word, innerThresh:word, hevThresh:word
	uses bx, cx, dx, ds, es, si, di
	.enter
		mov	cx, count
		jcxz	done
		lds	si, pixelsP
		mov	bx, acrossStep
		mov	dx, alongStep
		mov	ax, thresh
		mov	di, 4
		push	di		; normal filter with four-pixel smooth update
		push	innerThresh
		push	hevThresh
		call	WebPFilterEdge
done:
	.leave
		ret
WEBPFILTER24 endp

global WEBPFILTER26:far
WEBPFILTER26 proc far pixelsP:fptr, acrossStep:word, alongStep:word,
		count:word, thresh:word, innerThresh:word, hevThresh:word
	uses bx, cx, dx, ds, es, si, di
	.enter
		mov	cx, count
		jcxz	done
		lds	si, pixelsP
		mov	bx, acrossStep
		mov	dx, alongStep
		mov	ax, thresh
		mov	di, 6
		push	di		; normal filter with six-pixel smooth update
		push	innerThresh
		push	hevThresh
		call	WebPFilterEdge
done:
	.leave
		ret
WEBPFILTER26 endp

	;
	; Filter a complete edge without unlocking buffers or calling GEOS.
	; Original samples and corrections occupy 24 bytes of local storage.
	; All arithmetic fits signed words: decision <=1275, weighted update <3500.
	; SI/DI are unsigned offsets into the caller's locked segment.
	;
WebPFilterEdge proc near filterKind:word, innerThresh:word, hevThresh:word
p2		local	word
p1		local	word
p0		local	word
q0		local	word
q1		local	word
q2		local	word
a1		local	word
a2		local	word
a3		local	word
advance		local	word
limit		local	word
updateCount	local	word
	.enter
		mov	advance, dx
		add	ax, ax
		inc	ax		; the reference uses 2 * thresh + 1
		mov	limit, ax
filterSample:
		mov	di, si
		sub	di, bx
		sub	di, bx		; p[-2 * acrossStep]
		WebPLoadPixel
		mov	p1, ax
		add	di, bx
		WebPLoadPixel
		mov	p0, ax
		add	di, bx
		WebPLoadPixel
		mov	q0, ax
		add	di, bx
		WebPLoadPixel
		mov	q1, ax

		mov	ax, p0
		sub	ax, q0
		WebPAbsAX
		add	ax, ax
		add	ax, ax		; four times the center difference
		mov	dx, ax
		mov	ax, p1
		sub	ax, q1
		WebPAbsAX
		add	ax, dx
		cmp	ax, limit
		LONG ja	nextSample	; equality permits filtering
		cmp	filterKind, 0
		LONG je	filterTwo	; simple filtering reads only four samples

		mov	di, si
		sub	di, bx
		sub	di, bx
		sub	di, bx		; p[-3 * acrossStep]
		WebPLoadPixel
		mov	p2, ax
		sub	di, bx
		WebPLoadPixel
		WebPInnerCheck p2	; p3 - p2
		mov	ax, p2
		WebPInnerCheck p1
		mov	ax, p1
		WebPInnerCheck p0
		mov	ax, q1
		WebPInnerCheck q0
		mov	di, si
		add	di, bx
		add	di, bx		; p[2 * acrossStep]
		WebPLoadPixel
		mov	q2, ax
		WebPInnerCheck q1
		add	di, bx
		WebPLoadPixel
		WebPInnerCheck q2	; q3 - q2

		mov	ax, p1
		sub	ax, p0
		WebPAbsAX
		cmp	ax, hevThresh
		LONG ja	filterTwo	; HEV uses strict greater-than
		mov	ax, q1
		sub	ax, q0
		WebPAbsAX
		cmp	ax, hevThresh
		LONG ja	filterTwo
		cmp	filterKind, 4
		LONG je	filterFour

	;
	; Six-pixel update: clip a first, then derive all three corrections.
	;
		mov	ax, p1
		sub	ax, q1
		call	WebPClipSigned
		mov	dx, ax
		mov	ax, q0
		sub	ax, p0
		add	dx, ax
		add	ax, ax
		add	ax, dx		; 3 * (q0 - p0) + clipped (p1 - q1)
		call	WebPClipSigned
		mov	dx, ax
		add	ax, ax
		add	ax, ax
		add	ax, ax
		add	ax, dx		; 9 * a
		mov	dx, ax
		add	ax, 63
		WebPShiftAX 7
		mov	a3, ax
		mov	ax, dx
		add	ax, dx		; 18 * a
		add	ax, 63
		WebPShiftAX 7
		mov	a2, ax
		mov	ax, dx
		add	ax, dx
		add	ax, dx		; 27 * a
		add	ax, 63
		WebPShiftAX 7
		mov	a1, ax

		mov	di, si
		sub	di, bx
		sub	di, bx
		sub	di, bx
		mov	ax, p2
		add	ax, a3
		call	WebPStorePixel
		add	di, bx
		mov	ax, p1
		add	ax, a2
		call	WebPStorePixel
		add	di, bx
		mov	ax, p0
		add	ax, a1
		call	WebPStorePixel
		add	di, bx
		mov	ax, q0
		sub	ax, a1
		call	WebPStorePixel
		add	di, bx
		mov	ax, q1
		sub	ax, a2
		call	WebPStorePixel
		add	di, bx
		mov	ax, q2
		sub	ax, a3
		call	WebPStorePixel
		jmp	nextSample

	;
	; Four-pixel update omits the p1-q1 term and uses clipped deltas.
	;
filterFour:
		mov	updateCount, 4
		mov	ax, q0
		sub	ax, p0
		mov	dx, ax
		add	ax, ax
		add	ax, dx		; 3 * (q0 - p0)
		jmp	short deltas

	;
	; Simple filtering and HEV both use the two-pixel update.
	;
filterTwo:
		mov	updateCount, 2
		mov	ax, p1
		sub	ax, q1
		call	WebPClipSigned
		mov	dx, ax
		mov	ax, q0
		sub	ax, p0
		add	dx, ax
		add	ax, ax
		add	ax, dx		; 3 * (q0 - p0) + clipped (p1 - q1)
deltas:
		mov	dx, ax
		add	ax, 4
		WebPShiftAX 3
		call	WebPClipDelta
		mov	a1, ax
		inc	ax
		sar	ax, 1		; four-pixel outer correction: (a1 + 1) >> 1
		mov	a3, ax
		mov	ax, dx
		add	ax, 3
		WebPShiftAX 3
		call	WebPClipDelta
		mov	a2, ax
		mov	di, si
		sub	di, bx
		cmp	updateCount, 4
		jne	centerPixels
		sub	di, bx
		mov	ax, p1
		add	ax, a3
		call	WebPStorePixel
		add	di, bx
centerPixels:
		mov	ax, p0
		add	ax, a2
		call	WebPStorePixel
		add	di, bx
		mov	ax, q0
		sub	ax, a1
		call	WebPStorePixel
		cmp	updateCount, 4
		jne	nextSample
		add	di, bx
		mov	ax, q1
		sub	ax, a3
		call	WebPStorePixel
nextSample:
		add	si, advance
		dec	cx
		LONG jnz filterSample
	.leave
		ret
WebPFilterEdge endp

	;
	; Signed clipping helpers preserve loop registers and the original samples.
	;
WebPClipSigned proc near
		cmp	ax, -128
		jge	upperBound
		mov	ax, -128
		ret
upperBound:
		cmp	ax, 127
		jle	done
		mov	ax, 127
done:
		ret
WebPClipSigned endp

WebPClipDelta proc near
		cmp	ax, -16
		jge	upperBound
		mov	ax, -16
		ret
upperBound:
		cmp	ax, 15
		jle	done
		mov	ax, 15
done:
		ret
WebPClipDelta endp

	;
	; Clip AX to an unsigned pixel and store it at DS:DI.
	;
WebPStorePixel proc near
		tst	ax
		jns	upperBound
		clr	ax
upperBound:
		cmp	ax, 255
		jle	store
		mov	ax, 255
store:
		mov	ds:[di], al
		ret
WebPStorePixel endp

WebPDspCode ends
