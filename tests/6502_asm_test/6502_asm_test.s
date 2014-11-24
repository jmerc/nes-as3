
; Assembling this file should generate same object code as
; other file

main:
	BRK
	.word $3412
	ORA [$12,X]
	.byte $34
		.byte $02, $12, $34
		.byte $03, $12, $34
		.byte $04, $12, $34
	ORA <$12
	.byte $34
	ASL <$12
	.byte $34
		.byte $07, $12, $34
	PHP
	.word $3412
	ORA #$12
	.byte $34
	ASL	A
	.word $3412
		.byte $0B, $12, $34
		.byte $0C, $12, $34
	ORA $3412
	ASL $3412
		.byte $0F, $12, $34
	BPL	bpl_dest
	.byte $34
	ORA [$12],Y
	.byte $34
		.byte $12, $12, $34
		.byte $13, $12, $34
		.byte $14, $12, $34
	ORA <$12,X
	.byte $34
	ASL <$12,X
bpl_dest:
	.byte $34
		.byte $17, $12, $34
	CLC
	.word $3412
	ORA $3412,Y
		.byte $1A, $12, $34
		.byte $1B, $12, $34
		.byte $1C, $12, $34
	ORA $3412,X
	ASL $3412,X
		.byte $1F, $12, $34
	JSR $3412
	AND [$12,X]
	.byte $34
		.byte $22, $12, $34
		.byte $23, $12, $34
	BIT <$12
	.byte $34
	AND <$12
	.byte $34
	ROL <$12
	.byte $34
		.byte $27, $12, $34
	PLP
	.word $3412
	AND #$12
	.byte $34
	ROL A
	.word $3412

		.byte $2B, $12, $34
	BIT $3412
	AND $3412
	ROL $3412
		.byte $2F, $12, $34
	BMI	bmi_dest
	.byte $34
	AND [$12],Y
	.byte $34
		.byte $32, $12, $34
		.byte $33, $12, $34
		.byte $34, $12, $34
	AND <$12,X
	.byte $34
	ROL <$12,X
bmi_dest:
	.byte $34
		.byte $37, $12, $34
	SEC
	.word $3412
	AND $3412,Y
		.byte $3A, $12, $34
		.byte $3B, $12, $34
		.byte $3C, $12, $34
	AND $3412,X
	ROL $3412,X
		.byte $3F, $12, $34
	RTI
	.word $3412
	EOR [$12,X]
	.byte $34
		.byte $42, $12, $34
		.byte $43, $12, $34
		.byte $44, $12, $34
	EOR <$12
	.byte $34
	LSR <$12
	.byte $34
		.byte $47, $12, $34
	PHA
	.word $3412
	EOR #$12
	.byte $34
	LSR A
	.word $3412	
		.byte $4B, $12, $34
	JMP $3412
	EOR $3412
	LSR $3412
		.byte $4F, $12, $34
	BVC	bvc_dest
	.byte $34
	EOR [$12],Y
	.byte $34
		.byte $52, $12, $34
		.byte $53, $12, $34
		.byte $54, $12, $34
	EOR <$12,X
	.byte $34
	LSR <$12,X
bvc_dest:
	.byte $34
		.byte $57, $12, $34
	CLI
	.word $3412
	EOR $3412,Y
		.byte $5A, $12, $34
		.byte $5B, $12, $34
		.byte $5C, $12, $34
	EOR $3412,X
	LSR $3412,X
		.byte $5F, $12, $34
	RTS
	.word $3412
	ADC [$12,X]
	.byte $34
		.byte $62, $12, $34
		.byte $63, $12, $34
		.byte $64, $12, $34
	ADC <$12
	.byte $34
	ROR <$12
	.byte $34
		.byte $67, $12, $34
	PLA
	.word $3412
	ADC #$12
	.byte $34
	ROR A
	.word $3412
		.byte $6B, $12, $34
	JMP [$3412]
	ADC $3412
	ROR $3412
		.byte $6F, $12, $34
	BVS	bvs_dest
	.byte $34
	ADC [$12],Y
	.byte $34
		.byte $72, $12, $34
		.byte $73, $12, $34
		.byte $74, $12, $34
	ADC <$12,X
	.byte $34
	ROR <$12,X
bvs_dest:
	.byte $34
		.byte $77, $12, $34
	SEI
	.word $3412
	ADC $3412,Y
		.byte $7A, $12, $34
		.byte $7B, $12, $34
		.byte $7C, $12, $34
	ADC $3412,X
	ROR $3412,X
		.byte $7F, $12, $34
		.byte $80, $12, $34
	STA [$12,X]
	.byte $34
		.byte $82, $12, $34
		.byte $83, $12, $34
	STY <$12
	.byte $34
	STA <$12
	.byte $34
	STX <$12
	.byte $34
		.byte $87, $12, $34
	DEY
	.word $3412
		.byte $89, $12, $34
	TXA
	.word $3412
		.byte $8B, $12, $34
	STY $3412
	STA $3412
	STX $3412
		.byte $8F, $12, $34
	BCC	bcc_dest
	.byte $34
	STA [$12],Y
	.byte $34
		.byte $92, $12, $34
		.byte $93, $12, $34
	STY <$12,X
	.byte $34
	STA <$12,X
	.byte $34
	STX <$12,Y
bcc_dest:
	.byte	$34
		.byte $97, $12, $34
	TYA
	.word $3412
	STA $3412,Y
	TXS
	.word $3412
		.byte $9B, $12, $34
		.byte $9C, $12, $34
	STA $3412,X
		.byte $9E, $12, $34
		.byte $9F, $12, $34
	LDY #$12
	.byte $34
	LDA [$12,X]
	.byte $34
	LDX #$12
	.byte $34
		.byte $A3, $12, $34
	LDY <$12
	.byte $34
	LDA <$12
	.byte $34
	LDX <$12
	.byte $34
		.byte $A7, $12, $34
	TAY
	.word $3412
	LDA #$12
	.byte $34
	TAX
	.word $3412
		.byte $AB, $12, $34
	LDY $3412
	LDA $3412
	LDX $3412
		.byte $AF, $12, $34
	BCS	bcs_dest
	.byte $34
	LDA [$12],Y
	.byte $34
		.byte $B2, $12, $34
		.byte $B3, $12, $34
	LDY <$12,X
	.byte $34
	LDA <$12,X
	.byte $34
	LDX <$12,Y
bcs_dest:
	.byte $34
		.byte $B7, $12, $34
	CLV
	.word $3412
	LDA $3412,Y
	TSX
	.word $3412
		.byte $BB, $12, $34
	LDY $3412,X
	LDA $3412,X
	LDX $3412,Y
		.byte $BF, $12, $34
	CPY #$12
	.byte $34
	CMP [$12,X]
	.byte $34
		.byte $C2, $12, $34
		.byte $C3, $12, $34
	CPY <$12
	.byte $34
	CMP <$12
	.byte $34
	DEC <$12
	.byte $34
		.byte $C7, $12, $34
	INY
	.word $3412
	CMP #$12
	.byte $34
	DEX
	.word $3412
		.byte $CB, $12, $34
	CPY $3412
	CMP $3412
	DEC $3412
		.byte $CF, $12, $34
	BNE	bne_dest
	.byte $34
	CMP [$12],Y
	.byte $34
		.byte $D2, $12, $34
		.byte $D3, $12, $34
		.byte $D4, $12, $34
	CMP <$12,X
	.byte $34
	DEC <$12,X
bne_dest:
	.byte $34
		.byte $D7, $12, $34
	CLD
	.word $3412
	CMP $3412,Y
		.byte $DA, $12, $34
		.byte $DB, $12, $34
		.byte $DC, $12, $34
	CMP $3412,X
	DEC $3412,X
		.byte $DF, $12, $34
	CPX #$12
	.byte $34
	SBC [$12,X]
	.byte $34
		.byte $E2, $12, $34
		.byte $E3, $12, $34
	CPX <$12
	.byte $34
	SBC <$12
	.byte $34
	INC <$12
	.byte $34
		.byte $E7, $12, $34
	INX
	.word $3412
	SBC #$12
	.byte $34
	NOP
	.word $3412
		.byte $EB, $12, $34
	CPX $3412
	SBC $3412
	INC $3412
		.byte $EF, $12, $34
	BEQ	beq_dest
	.byte $34
	SBC [$12],Y
	.byte $34
		.byte $F2, $12, $34
		.byte $F3, $12, $34
		.byte $F4, $12, $34
	SBC <$12,X
	.byte $34
	INC <$12,X
beq_dest:
	.byte $34
		.byte $F7, $12, $34
	SED
	.word $3412
	SBC $3412,Y
		.byte $FA, $12, $34
		.byte $FB, $12, $34
		.byte $FC, $12, $34
	SBC $3412,X
	INC $3412,X
		.byte $FF, $12, $34

