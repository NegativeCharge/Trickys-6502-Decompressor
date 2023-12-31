; There is a commented out INC after .done, that is only useful if you have more than 2 consecutive compressed blocks.
; Adding the final INC would increase the size of this code from 72 (+ RTS) bytes to 78, 79 including the RTS.
; The code could be prefixed with stx/sty to either src or dst, if that is used multiple times.
; The decompress will fail if wrapping arround to &0000 starts with a RAW sequence - see #1

.decompress
{
	ldx #0                  ; (zp,x) will be used to access (zp,0)
.for
	lda (decompress_src,x)  ; next control byte
	beq done                ; 0 signals end of decompression
	bpl copy_raw            ; msb=0 means just copy this many bytes from source
	clc
	adc #&80 + 2            ; flip msb, then add 2, we wont request 0 or 1 as that wouldn't save anything
	sta decompress_tmp      ; count of bytes to copy (>= 2)
	ldy #1                  ; byte after control is offset
	lda (decompress_src),y  ; offset from current src - 256
	tay
	{
		lda decompress_src  ; advance src past the control byte and offset
		clc
		adc #2
		sta decompress_src
		bcc pg
		inc decompress_src+1
	.pg
	}
.copy_previous              ; copy tmp bytes from dst - 256 + offset
{
	dec decompress_dst+1    ; -256
	lda (decompress_dst),y  ; +y
	inc decompress_dst+1    ; +256
	sta (decompress_dst,x)  ; +0
	{
		inc decompress_dst  ; INC dst (used for both src of copy (-256) and dst)
		bne pg
		inc decompress_dst+1
	.pg
	}
	dec decompress_tmp      ; count down bytes to copy
	bne copy_previous
	beq for                 ; after copying, go back for next control byte
}
.copy_raw
{
	tay                     ; bytes to copy from src
.copy
	{
		inc decompress_src  ; INC src (1st time past control byte)
		bne pg
		inc decompress_src+1
	.pg
	}
	dey
	bmi for
	lda (decompress_src,x)  ; copy bytes
	sta (decompress_dst,x)
	{
		inc decompress_dst  ; INC dst
		bne pg
		inc decompress_dst+1
	.pg
	}
	bne copy                ; rest of bytes ; #1 replace with jmp if wrapping back to &0000 is required
}
.done

; on exit X=A=0

;{
;	inc decompress_src  ; INC src to after terminating 0, see note in compress.asm
;	bne pg
;	inc decompress_src+1
;.pg
;}

	RTS                 ; must add an RTS
}
