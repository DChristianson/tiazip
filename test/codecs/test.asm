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


audio_stream_idx    ds 1
symbol_table        ds 1
audio_stream_ptr
audio_stream_lo
audio_stream_hi = . + 1
audio_data_0_ptr   ds 2 ; channel 0 data stream
audio_data_1_ptr   ds 2 ; channel 1 data stream
audio_span_0_ptr   ds 2 ; channel 0 span stream
audio_span_1_ptr   ds 2 ; channel 1 span stream

audio_timer
audio_stream_buf  
audio_data_0_buf   ds 1 ; channel 0 data stream
audio_timer_0      ds 1
audio_data_1_buf   ds 1 ; channel 1 data stream
audio_timer_1      ds 1
audio_span_0_buf   ds 1 ; channel 0 span stream
symbol        ds 1
audio_span_1_buf   ds 1 ; channel 1 span stream
curr_code_len      ds 1

first_code  ds 1
first_idx   ds 1
message     ds 7
message_len ds 1

; === CODE ===
  SEG CODE
    ORG $F000

Start:
  CLEAN_START
  ldx #6
  ldy #0
InitStreamsLoop:
  lda #<(bitstream-1)
  sta audio_stream_lo,x
  lda #>(bitstream-1)
  sta audio_stream_hi,x
  sty audio_stream_buf,x
  dex
  dex
  bpl InitStreamsLoop

  ; decode n symbols
  jsr Decode
  ldy #RED
  ldx message_len
  dex
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

  SEG PLAYBACK
    ORG $F100

; --- Bit reading ---

Decode:
DecodeLoop:
  lda #SAMPLE_DECODE
  ldy #sample_CODES
  jsr DecodeSymbol
  lda symbol
  ldy message_len
  sta message,y
  iny
  sty message_len
  cpy #7
  bne DecodeLoop
  rts

ReadBit:
            ; read one data bit from audio stream
            ; uses a sentinel bit and a few tricks picked up from
            ; http://forum.6502.org/viewtopic.php?f=2&t=4642    
audio_read_bit
            ldx audio_stream_idx
            asl audio_stream_buf,x
            bne _audio_read_bit_end
            inc audio_stream_lo,x
            bne _audio_read_bit_same_page
            inc audio_stream_hi,x
_audio_read_bit_same_page
            lda (audio_stream_ptr,x)
            sec ; set sentinel bit
            rol
            sta audio_stream_buf,x
_audio_read_bit_end
            rol symbol
            inc curr_code_len
            rts

; --- Canonical Huffman Decoder ---

DecodeSymbol:
  sta curr_code_len
  sty first_idx 

  lda #0
  sta symbol
  sta first_code

ReadNextBit:
  jsr ReadBit
  ldy curr_code_len
  lda symbol 
  sec
  sbc DECODE_LENGTHS,y
  bcc ReturnSymbol
  cmp first_code
  bcc ReturnSymbol

  lda DECODE_LENGTHS,y ; first_code = (first_code + count[curr_len]) << 1
  clc
  adc first_code
  asl
  sta first_code
  
  lda DECODE_LENGTHS,y ; first_idx = first_idx + count[curr_len]
  clc
  adc first_idx
  sta first_idx
  jmp ReadNextBit

ReturnSymbol:
  lda symbol         ; huffman coded symbol
  sec
  sbc first_code      ; offset = curr_code - first_code
  clc
  adc first_idx      ; symbol index = offset + symbol_off
  tay
  lda symbols,y
  sta symbol
  rts

  SEG DATA
    ORG $F200

; === DATA ===



expected:
  .byte 0x66, 0x65, 0x67, 0x65, 0x68, 0x66, 0x65

; Encoded bitstream 
bitstream:
  .byte %01011010, %11101000 ; padded with 0s

AUDIO_DATA_S0_C0_START
    byte $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    byte $80, $a2, $13, $8a, $46, $28, $3a, $a1, $68, $84, $a2, $13, $8a, $46, $28, $3a
    byte $a1, $68, $84, $a2, $13, $8a, $46, $58, $3c
; AUDIO_DATA_S0_C0 bytes: 41

AUDIO_DATA_S0_C1_START
    byte $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb
    byte $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $0f
; AUDIO_DATA_S0_C1 bytes: 25

AUDIO_TRACK_S0_C0_START
    byte $00, $00, $00, $00, $00, $00, $00, $00
; AUDIO_TRACK_S0_C0 bytes: 8

AUDIO_TRACK_S0_C1_START
    byte $00, $00, $00, $00, $00, $00, $00, $00
; AUDIO_TRACK_S0_C1 bytes: 8

CODE_STOP            = 0
CODE_WRITE_REGISTERS_010 = 1
CODE_WRITE_REGISTERS_011 = 2
CODE_WRITE_REGISTERS_111 = 3
CODE_VOL_INC         = 4
CODE_VOL_DEC         = 5
CODE_PAUSE           = 7
CODE_SUSTAIN         = 8
CODE_JUMP            = 9
CODE_BRANCH_POINT    = 10
CODE_SKIP            = 11
CODE_TAKE_DATA_JUMP  = 12
CODE_TAKE_TRACK_JUMP = 13
CODE_RETURN_LAST     = 14
CODE_RETURN_FF       = 15
CODE_RETURN_NOOP     = 16

DECODE_LENGTHS = . - 1
audio_decode_command_LENGTHS
DATA_DECODE = . - DECODE_LENGTHS - 1
    byte 1
    byte 1
    byte 1
    byte 2
audio_decode_span_LENGTHS
SPAN_DECODE = . - DECODE_LENGTHS - 1
    byte 1
SAMPLE_DECODE = . - DECODE_LENGTHS - 1
    .byte 1     ; 1 code of length 1
    .byte 1     ; 1 codes of length 2
    .byte 2     ; 2 codes of length 3

; Symbols in canonical order (sorted by length, then value)
symbols
audio_decode_command_CODES = . - symbols
    byte CODE_SUSTAIN; 0
    byte CODE_WRITE_REGISTERS_010; 10
    byte CODE_PAUSE; 110
    byte CODE_WRITE_REGISTERS_111; 1110
    byte CODE_BRANCH_POINT; 1111
audio_decode_span_CODES = . - symbols
    byte CODE_STOP; 0000000000000000000000000000000000000000000000000000000000000000
sample_CODES = . - symbols
  .byte 0x66, 0x65, 0x67, 0x68


; === VECTORS ===
  SEG VECTORS
  ORG $FFFA
  .word 0
  .word Start
  .word 0
