    MAC AUDIO_VARS

audio_stream_ptr
audio_data_0_ptr        ds 2 ; channel 0 data stream
audio_data_1_ptr        ds 2 ; channel 1 data stream
audio_track_0_ptr       ds 2 ; channel 0 track/jump stream
audio_track_1_ptr       ds 2 ; channel 1 track/jump stream

audio_data_last_addr         ; position where we took last jump in data stream
audio_data_0_last_addr  ds 2 ; 
audio_data_1_last_addr  ds 2 ; 
audio_data_max_addr          ; furthest read position in data stream
audio_data_0_max_addr   ds 2 ; 
audio_data_1_max_addr   ds 2 ;

audio_data_0_shift      ds 1
audio_track_0_shift     ds 1
audio_data_1_shift      ds 1
audio_track_1_shift     ds 1

audio_timer 
audio_timer_0       ds 1   ; 
audio_timer_1       ds 1   ; 
audio_track         ds 1
    ENDM

    IFNCONST audio_cx
audio_cx = AUDC0
audio_fx = AUDF0 
audio_vx ds 2
    ENDIF


    MAC AUDIO_CONTROLS
audio_inc_track
            ldy audio_track
            iny
            cpy #AUDIO_NUM_TRACKS
            bne _audio_track_save
            ldy #0
            beq _audio_track_save ; always true but cheaper than jump
audio_dec_track
            ldy audio_track
            dey
            bpl _audio_track_save
            ldy #(AUDIO_NUM_TRACKS - 1)
_audio_track_save
            sty audio_track
            rts
audio_play_track
            lda audio_track
            asl
            asl
            asl
            tay
            ldx #7
_audio_play_setup_loop
            lda AUDIO_TRACKS,y
            ; BUGBUG: will be off
            sta audio_data_ptr,x
            sta audio_last_ptr,x
            sta audio_front_ptr,x
            iny
            dex
            bpl _audio_play_setup_loop
            lda #0
            sta audio_timer_0
            sta audio_timer_1
            sta audio_data_0_bits
            sta audio_data_1_bits
            rts
    ENDM

    MAC AUDIO_UPDATE

  // Test compression correctness 
  auto it = spanSequence.begin();
  size_t nextReadAddress = 0, compareAddress = 0;
  size_t maxOffset = 0;
  size_t returnAddress = 0;

  a = ReadNextData
  switch (a.type) {
    case CODE_TAKE_DATA_JUMP:
      a = readJump Address
      returnAddress = ceommandAddress+
      ceommandAddress = a
      break;
    case BRANCH_POINT:
      a = ReadNextTrack
      switch (a.type) {
        case STOP:
          stop
          break
        case SKIP:
          readNext
          break    
      case CODE_TAKE_DATA_JUMP:
 else if (s == CODE_RETURN_FF) {
        logD("return to front %d", maxOffset);
        nextReadAddress = maxOffset;
        it++;

      } else if (s == CODE_RETURN_LAST) {
        logD("return to last %d", returnAddress);
        nextReadAddress = returnAddress;             
      }
  }
  while (true) {
    AlphaCode c = compressedCodeSequence[nextReadAddress];
    CODE_TYPE codeType = GET_CODE_TYPE(c);
    } else if (codeType == CODE_TYPE::BRANCH_POINT) {
      nextReadAddress++;
      assert(it != spanSequence.end());
      AlphaCode s = *it++;
      CODE_TYPE spanType = GET_CODE_TYPE(s);
      if (s == CODE_STOP) {
        AlphaCode x = codeSequence[compareAddress];
        if (x != CODE_STOP) {
          logD("%d %d | %d: no stop found at %d: %016x", subsong, channel, nextReadAddress, compareAddress, x);
          assert(false);
        }
        assert(it == spanSequence.end());
        compareAddress++;
        break;
        
      } else if (s == CODE_SKIP) {
        // skip 1 in data stream 
        nextReadAddress++;
        
      } else if (s == CODE_TAKE_DATA_JUMP) {
        AlphaCode c = compressedCodeSequence[nextReadAddress];
        size_t jumpAddress = GET_CODE_JUMP_ADDRESS(c);
        assert(CODE_TYPE::JUMP == GET_CODE_TYPE(c));
        if (jumpAddress >= maxOffset) {
          logD("missed goto back to front");
        }
        if (jumpAddress == returnAddress) {
          logD("missed goto back to last");
        }
        returnAddress = nextReadAddress + 1;
        if (returnAddress >= maxOffset) {
          maxOffset = returnAddress;
        }
        logD("goto %d", jumpAddress);
        nextReadAddress = jumpAddress;

      } else if (s == CODE_RETURN_FF) {
        logD("return to front %d", maxOffset);
        nextReadAddress = maxOffset;
        it++;

      } else if (s == CODE_RETURN_LAST) {
        logD("return to last %d", returnAddress);
        nextReadAddress = returnAddress;
        it++;

      } else if (s == CODE_TAKE_TRACK_JUMP) {
        s = *it++;
        spanType = GET_CODE_TYPE(s);
        size_t jumpAddress = GET_CODE_JUMP_ADDRESS(s);
        if (jumpAddress >= maxOffset) {
          logD("missed jump back to front");
        }
        if (jumpAddress == returnAddress) {
          logD("missed jump back to last");
        }
        returnAddress = nextReadAddress + 1;
        if (returnAddress >= maxOffset) {
          maxOffset = returnAddress;
        }
        logD("jump to %d", jumpAddress);
        nextReadAddress = jumpAddress;

      } else {
        assert(false);
      }
    } else {
      AlphaCode x = codeSequence[compareAddress];
      if (c != x) {
        logD("%d %d | %d: %08x    %08x",subsong, channel, nextReadAddress, compressedCodeSequence[nextReadAddress-1], codeSequence[compareAddress-1]);
        logD("%d %d | %d: %08x <> %08x (%d)",subsong, channel, nextReadAddress, c, x, compareAddress);
        logD("%d %d | %d: %08x    %08x",subsong, channel, nextReadAddress+1, compressedCodeSequence[nextReadAddress+1], codeSequence[compareAddress+1]);
        assert(false);
      }
      nextReadAddress++;
      compareAddress++;
    }
  }
    
  logD("valid at %d/%d", compareAddress, codeSequence.size());
  assert(compareAddress == codeSequence.size());
}


audio_update
            ldx #2 ; loop over both audio channels
            ldy #1
_audio_loop
            lda audio_timer,x
            beq _audio_next_note
            dec audio_timer,x
            jmp _audio_next_channel
_audio_next_note
            
            ... do all the things
_audio_next_channel
            ldx #0
            dey
            bpl _audio_loop
            rts

_audio_track_jump
            ; pull an address from jump stream
            ...
_audio_track_return_last
            ...
_audio_track_return_front
            ...

_audio_skip
            ....

_audio_goto 
            
            inc audio_stream_ptr,x
            bne _audio_jump_same_page
            inc audio_stream_ptr+1,x
_audio_jump_same_page
            lda (audio_stream_ptr,x)

            clc
_load_first_byte            ror
            bne _load_first_byte
            lda audio_data_shift,x

            ; pull an address from data stream
            pha
            jsr audio_data_advance
            lda (audio_data_ptr,x) 
            sta audio_data_ptr,x
            pla
            sta audio_data_ptr+1,x
            jmp _audio_next_note

            ; read one data bit from audio stream
            ; uses a sentinel bit and a few tricks picked up from
            ; http://forum.6502.org/viewtopic.php?f=2&t=4642    
audio_read_bit
            lsr audio_stream_shift,x
            bne _audio_read_bit_end
            inc audio_stream_ptr,x
            bne _audio_read_bit_same_page
            inc audio_stream_ptr+1,x
_audio_read_bit_same_page
            lda (audio_stream_ptr,x)
            ror
            sta audio_stream_shift,x
_audio_read_bit_end
            rts

            ; jump to a location on the data stream
            ; address coords on stack
            ;  hhhhhlll lllllsss - h = high bits, l = low bits, s = shift
audio_jump_address
            ; BUGBUG: way to efficiently save last and front
            pla
            sta audio_stream_ptr+1,x
            pla
            sta audio_stream_ptr,x
            ; 3x shift down
            lsr audio_stream_ptr+1,x
            lsr audio_stream_ptr,x
            lsr audio_stream_ptr+1,x
            lsr audio_stream_ptr,x
            lsr audio_stream_ptr+1,x
            lsr audio_stream_ptr,x
            ; setup shift register
            and #$07
            tay
            lda (audio_stream_ptr,x)
            dey
            bmi _audio_shift_back
            sec
_audio_jump_shift
            lsr
            dey
            bne _audio_jump_shift
            sta audio_data_shift,x
            rts
_audio_shift_back
            lda audio_stream_ptr,x
            beq _audio_shift_back_same_page
            dec audio_stream_ptr+1,x
_audio_shift_back_same_page
            dec audio_stream_ptr,x
            lda #1
            sta audio_data_bits,x
            rts
    ENDM