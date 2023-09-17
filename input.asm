.segment "HEADER"

    .byte $4e, $45, $53, $1a
    .byte $02
    .byte $01
    .byte $00
    .byte $00
    .byte $00
    .byte $00
    .byte $00
    .byte $00, $00, $00, $00, $00

.segment "STARTUP"

reset:
;disable interrupts and decimal mode
    sei
    cld

;disable sound IRQ
    ldx #$40
    stx $4017

;initialize stack register
    ldx #$ff
    txs

    inx

;zero out the PPU registers.
    stx $2000
    stx $2001

;disable pcm.
    stx $4010

;wait for vblank
:
    bit $2002
    bpl :-

    txa

;clear the 2k of internal ram. ($0000–$07ff)
clearMem: 
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    ;prep $0200 - $02ff for dma / sprites
    lda #$ff
    sta $0200, x
    inx
    bne clearMem

;wait for vblank
:
    bit $2002
    bpl :-

;prep PPU $3f10 - $3f1f for sprite and background palettes
    lda #$3f
    sta $2006
    lda #$00
    sta $2006

    ldx #$00

;load in the palettes
loadPalettes:
    lda paletteData, X
    sta $2007
    inx
    cpx #$20
    bne loadPalettes    

;load in the sprite data
    ldx #$00
loadSprites:
    lda spriteData, X
    sta $0200, X
    inx
    cpx #$2a
    bne loadSprites 

;enable interrupts
    cli

;enable nmi and use second pattern table as background
    lda #%10010000
    sta $2000

;enable sprites and background
    lda #%00011110
    sta $2001

;no game logic yet, just loop
loop:
    jmp loop

;draw sprite data on vblank
nmi:
    lda #$02
    sta $4014

;write #$01 and #$00 to get the current state
;of the player 1 and player 2 controllers
getControllerstatus:
    lda #$01
    sta $4016
    lda #$00
    sta $4016

;button status for each controller is returned in the following order:
;A, B, Select, Start, Up, Down, Left, Right.
;in this program, we are ignoring / skipping over A, B, Start, Select
;and focusing on Up, Down, Left, Right.

readAButton: ;ignore
    lda $4016
    jmp readADone
readADone:

readBButton: ;ignore
    lda $4016
    jmp readBDone
readBDone:

readSelectButton: ;ignore
    lda $4016
    jmp readSelectDone
readSelectDone:

readStartButton: ;ignore
    lda $4016
    jmp readStartDone
readStartDone:

readUpButton:
    lda $4016
    and #%00000001
    beq readUpDone
    lda $0203
    clc
    adc #$01
    sta $0203
readUpDone:

readDownButton:
    lda $4016
    and #%00000001
    beq readDownDone
    lda $0203
    clc
    adc #$01
    sta $0203
readDownDone:

readLeftButton:
    lda $4016
    and #%00000001
    beq readLeftDone
    lda $0200
    clc
    sbc #$01
    sta $0200
readLeftDone:

readRightButton: 
    lda $4016
    and #%00000001
    beq readRightDone
    lda $0200
    clc
    adc #$01
    sta $0200
readRightDone:

;return from interrupt
    rti

paletteData:
;background
    .byte $1d, $1d, $1d, $1d, $1d, $1d, $1d, $1d, $1d, $1d, $1d, $1d, $1d, $1d, $1d, $1d
;sprites
    .byte $1d, $01, $11, $21, $1d, $03, $13, $23, $1d, $07, $17, $27, $1d, $0a, $1a, $2a


spriteData:
;[ypos][sprite#][attrib][xpos]
    .byte $8c, $00, $00, $80
    .byte $8c, $01, $00, $88
    .byte $8c, $02, $00, $90
    .byte $94, $10, $00, $80
    .byte $94, $11, $00, $88
    .byte $94, $12, $00, $90

.segment "ZEROPAGE"

.segment "CODE"

.segment "VECTORS"
    .word nmi
    .word reset
    
.segment "CHARS"
;load graphics chr
    .incbin "sprites.chr"