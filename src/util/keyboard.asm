
; Group Bit	0	1	2	3	4	5	6	7
; Group Mask	FE	FD	FB	F7	EF	DF	BF	7F
; Key Bit	(Mask)
; 0	(FE)	DOWN	ENTER	(-)	.	0		F5		
; 1	(FD)	LEFT	+	3	2	1	STO	F4		
; 2	(FB)	RIGHT	-	6	5	4	,	F3		
; 3	(F7)	UP	*	9	8	7	x2	F2		
; 4	(EF)		/	)	(	EE	LN	F1		
; 5	(DF)		^	TAN	COS	SIN	LOG	2nd		
; 6	(BF)		CLEAR	CUSTOM	PRGM	TABLE	GRAPH	EXIT		
; 7	(7F)				DEL	x-VAR	ALPHA	MORE	


;waits until keypress is detected.
WaitForKey:
    ld hl, ti.DI_Mode
    ld (hl), 2

    xor a
.waitLoop:
    cp (hl)
    jp nz, .waitLoop

    ret
