  processor 6502
  include "vcs.h"
  include "macro.h"

NTSC = 0
PAL = 1

SYSTEM = NTSC

#if SYSTEM = NTSC
; NTSC Colors
BLUE = $A0
RED = $30
GREEN = $B3
WHITE = $0f
BLACK = 0
SCANLINES = 190
OVERSCAN_HEIGHT = 30
#else
; PAL Colors
BLUE = $90
GREEN = $72
RED = $40
WHITE = $0E
BLACK = 0
SCANLINES = 190
OVERSCAN_HEIGHT = 30
#endif

; === ZEROPAGE ===
  SEG.U variables

    ORG $80

bitbuf      ds 1
bitcount    ds 1
stream_ptr
stream_lo   ds 1
stream_hi   ds 1
curr_code   ds 1
curr_len    ds 1
symbol      ds 1
first_code  ds 1
first_idx   ds 1
message     ds 7
message_len = . - message

; === CODE ===
  SEG CODE
    ORG $F000

Start:
  CLEAN_START
  lda #<(bitstream-1)
  sta stream_lo
  lda #>(bitstream-1)
  sta stream_hi

  ; decode n symbols
  ldx #(message_len - 1)
DecodeLoop:
  jsr DecodeSymbol
  lda symbol
  sta message,x
  dex
  bpl DecodeLoop
  ldy #RED
  ldx #(message_len - 1)
TestLoop:
  lda message,x
  cmp expected,x
  bne TestDone
  dex
  bpl TestLoop
  ldy #GREEN
TestDone
  sty COLUBK    
Forever
    ; 3 scanlines of vertical sync signal to follow

            ldx #%00000010
            stx VSYNC               ; turn ON VSYNC bit 1
            ldx #0

            sta WSYNC               ; wait a scanline
            sta WSYNC               ; another
            sta WSYNC               ; another = 3 lines total

            stx VSYNC               ; turn OFF VSYNC bit 1

    ; 34 scanlines of vertical blank to follow

;--------------------
; VBlank start

            lda #%00000010
            sta VBLANK

            lda #42    ; vblank timer will land us ~ on scanline 34
            sta TIM64T

waitOnVBlank
            ldx #$00
waitOnVBlank_loop          
            cpx INTIM
            bmi waitOnVBlank_loop
            stx VBLANK
            sta WSYNC ; SL 38
            
            ldx #SCANLINES
gradient_loop
            sta WSYNC
            dex
            bne gradient_loop

;--------------------
; Footer + Overscan 

            ldx #OVERSCAN_HEIGHT
overscan_loop
            sta WSYNC
            dex
            bne overscan_loop
            jmp Forever


; --- Bit reading ---


ReadBit:
            ; read one data bit from audio stream
            ; uses a sentinel bit and a few tricks picked up from
            ; http://forum.6502.org/viewtopic.php?f=2&t=4642    
audio_read_bit
            asl bitbuf
            bne _audio_read_bit_end
            inc stream_lo
            bne _audio_read_bit_same_page
            inc stream_hi
_audio_read_bit_same_page
            ldy #0
            lda (stream_ptr),y
            sec ; set sentinel bit
            rol
            sta bitbuf
_audio_read_bit_end
            rol curr_code
            inc curr_len
            rts



COMP_ReadBit:
  lda bitcount
  bne ShiftBit

LoadNewByte:
  ldy #0
  lda (stream_ptr),y
  sta bitbuf
  inc stream_lo
  bne SkipHi
  inc stream_hi
SkipHi:
  lda #8
  sta bitcount

ShiftBit:
  asl bitbuf
  rol curr_code
  dec bitcount
  inc curr_len
  rts

; --- Canonical Huffman Decoder ---

DecodeSymbol:
  lda #0
  sta curr_code
  sta curr_len
  sta first_code
  sta first_idx

ReadNextBit:
  jsr ReadBit
  ldy curr_len
  lda curr_code 
  sec
  sbc code_counts,y
  bcc ReturnSymbol
  cmp first_code
  bcc ReturnSymbol

  lda code_counts,y ; first_code = (first_code + count[curr_len]) << 1
  clc
  adc first_code
  asl
  sta first_code
  
  lda code_counts,y ; first_idx = first_idx + count[curr_len]
  clc
  adc first_idx
  sta first_idx
  jmp ReadNextBit

ReturnSymbol:
  lda curr_code
  sec
  sbc first_code      ; offset = curr_code - first_code
  clc
  adc first_idx      ; symbol index = offset + symbol_off
  tay
  lda symbols,y
  sta symbol
  rts


; === DATA ===

code_counts:
    .byte 0     ; length 0 unused
    .byte 1     ; 1 code of length 1
    .byte 1     ; 1 codes of length 2
    .byte 2     ; 2 codes of length 3

; Symbols in canonical order (sorted by length, then value)
symbols:
  .byte 0x66, 0x65, 0x67, 0x68

expected:
  .byte 0x65, 0x66, 0x68, 0x65, 0x67, 0x65, 0x66

; Encoded bitstream 
bitstream:
    .byte %01011010, %11101000 ; padded with 0s

; === VECTORS ===
  SEG VECTORS
  ORG $FFFA
  .word 0
  .word Start
  .word 0
