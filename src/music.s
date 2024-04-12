
;==============================================================================
;
; MUSIC.S
;
; Samuel Volk
;
;==============================================================================

.INCLUDE "gb_hardware.i"
.INCLUDE "header.i"
.INCLUDE "music.i"

;==============================================================================
; WRAM DEFINITIONS
;==============================================================================

.DEFINE NUM_MUSIC_CHANS     4           ; total number of virtual music channels

.RAMSECTION "MusicVars" BANK 0 SLOT 3   ; Internal WRAM
    MusicTicks:         db
    MusicTickLimit:     db
    MusicPointer:       dsw NUM_MUSIC_CHANS
    MusicTimers:        ds  NUM_MUSIC_CHANS
    MusicOctaves:       ds  NUM_MUSIC_CHANS
    MusicVoices:        dsw 3
.ENDS

;==============================================================================
; AUDIO CONSTANTS
;==============================================================================

.SECTION "AudioConstants" FREE
Pitches:
.DW $F82C   ; C     1
.DW $F89D   ; C#    2
.DW $F907   ; D     3
.DW $F96B   ; D#    4
.DW $F9CA   ; E     5
.DW $FA23   ; F     6
.DW $FA77   ; F#    7
.DW $FAC7   ; G     8
.DW $FB12   ; G#    9
.DW $FB58   ; A     a
.DW $FB9B   ; A#    b
.DW $FBDA   ; B     c
.ENDS

;==============================================================================
; SUBROUTINES
;==============================================================================
.SLOT 0
.SECTION "MusicSubroutines" FREE

InitAudio:
    ; Turns on audio processor unit and all channels

    ldh a, (R_NR52)
    and %10000000           ; check if audio is already on
    ret nz
    ; init audio
    ld a, %10000000         ; sound on
    ldh (R_NR52), a
    ld a, %01000100         ; volume
    ldh (R_NR50), a
    ld a, $FF               ; enable all channels to both L&R
    ldh (R_NR51), a
    ret

StopAudio:
    ; Turns off audio processor unit, stopping all sounds

    ldh a, (R_NR52)
    and %10000000           ; check if audio is on
    ret z                   ; audio is off already
    ; turn off audio
    xor a
    ldh (R_NR50), a
    ldh (R_NR51), a
    ldh (R_NR52), a
    ret


StopMusic:
    ; disabling channels like this is supposed to prevent audio popping
    ld a, $08
    ldh (R_NR12), a
    ldh (R_NR22), a
    ldh (R_NR32), a
    ldh (R_NR42), a
    ld a, $80
    ldh (R_NR14), a
    ldh (R_NR24), a
    ldh (R_NR34), a
    ldh (R_NR44), a
    ret

LoadWaveform:
    ; hl    address to load from
    ld de, _WAVERAM
    ld c, 16
-   ldi a, (hl)
    ld (de), a
    inc de
    dec c
    jr nz, -
    ret

LoadMusic:
    ; Loads music to play
    ; hl    address to load from

    ; load tempo
    ldi a, (hl)
    ld (MusicTickLimit), a

    ; load instruments/voices
    ; voice 1
    ld de, MusicVoices
.REPEAT 3
    ld bc, Instruments
    ldi a, (hl)
    add a		    ; 2 bytes for instruments/voices
    add c
    ld c, a
    ld a, 0
    adc b
    ld a, (bc)
    ld (de), a
    inc bc
    inc de
    ld a, (bc)
    ld (de), a
    inc de
.ENDR

    ; load pointers to channels
    ld c, $00
    ld de, MusicPointer
-   ldi a, (hl)		    ; lsb
    ld (de), a
    inc de
    ldi a, (hl)		    ; msb
    ld (de), a
    inc de
    inc c
    ld a, NUM_MUSIC_CHANS
    cp c
    jr nz, -

    ; zero timers
    xor a
    ld hl, MusicTimers
.REPEAT NUM_MUSIC_CHANS
    ldi (hl), a
.ENDR

    ; reset octaves
    ld a, 3
    ld hl, MusicOctaves
.REPEAT NUM_MUSIC_CHANS
    ldi (hl), a
.ENDR
    ret

UpdateMusic:
    ; check to see update is needed (counter will equal ticks)
    ld a, (MusicTickLimit)
    ld b, a
    ld a, (MusicTicks)
    inc a
    cp b
    ld (MusicTicks), a
    ret nz          ; no update needed
    xor a           ; zero music counter, will do an update
    ld (MusicTicks), a

    ld c, 0         ; start with channel 0
    ld b, 0
@readSongData:
    ; load first song byte
    ld hl, MusicPointer
    add hl, bc          ; channel offset
    add hl, bc
    ldi a, (hl)         ; lower byte of music pointer
    ld e, a
    ldd a, (hl)         ; upper byte of music pointer
    ld d, a
    ld a, (de)          ; get next music byte

    ; Check for various commands and special cases
    cp MUSCMD_END               ; if the next byte $00...
    jp z, @nextChannel          ; ...means score is done
    cp MUSCMD_TEMPO
    jr z, @tempoCmd
    cp MUSCMD_LOOP
    jr z, @loopCmd
    cp MUSCMD_VOICE
    jr z, @ChVoiceCmd

    ; some single byte cmds we need to check for
    ld d, a
    and $F0
    cp MUSCMD_REST
    jr z, @restCmd
    cp MUSCMD_OCTAVE
    jr z, @octaveCmd
    jr @checkTimer              ; check timers before handling like a note

@tempoCmd:
    ldi a, (hl)
    ld e, a
    ldd a, (hl)                 ; decrement to go back for when storing again
    ld d, a
    inc de
    ld a, (de)
    inc de
    ld (MusicTickLimit), a      ; set new frame ticks limit/tempo
    ld a, e
    ldi (hl), a
    ld a, d
    ld (hl), a
    jp @readSongData

@loopCmd:                       ; ...loop back by moving the pointer
    inc de
    ld a, (de)                  ; get next music byte (loop addr low)
    ldi (hl), a
    inc de
    ld a, (de)                  ; get next music byte (loop addr high)
    ldd (hl), a
    jp @readSongData

@ChVoiceCmd:                    ; edit the channel's MusicVoice data
    inc de
    ld a, (de)                  ; load argument
    push de                     ; store MusicPointer value for later
    ld e, a
    xor a
    ld d, a
    ; add argument to Instruments to get instrument
    ld hl, Instruments
    add hl, de
    ; add channel offset (c) to MusicVoices to get destination
    ld de, MusicVoices
    ld a, c
    add e
    ld a, 0
    adc d                       ; handle carry to d
    ld e, a
    ldi a, (hl)                 ; move instrument to destination (2 bytes)
    ld (de), a
    inc de
    ld a, (hl)
    ld (de), a
    pop de                      ; retrieve MusicPointer value
    ld hl, MusicPointer
    add hl, bc
    add hl, bc
    inc de                      ; advance it
    ld a, e
    ldi (hl), a
    ld a, d
    ld (hl), a                  ; store it back
    jp @readSongData

@octaveCmd:
    ld a, d
    and $0F
    ld b, a
    ld de, MusicOctaves
    ld a, c
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    ld a, b
    ld (de), a                  ; store new octave
    ld b, 0
    ld hl, MusicPointer         ; we need to increment music pointer
    add hl, bc
    add hl, bc
    ldi a, (hl)
    ld e, a
    ld a, (hl)
    ld d, a
    inc de
    ld a, d
    ldd (hl), a
    ld a, e
    ld (hl), a
    jp @readSongData

@checkRest:
    ld d, a
    and $F0
    cp $70
    jr nz, @checkTimer

@restCmd:
    ; it's a rest
    ld a, d
    and $0F
    dec a
    ld d, a

    ld hl, MusicTimers
    add hl, bc                  ; channel offset
    ld a, (hl)                  ; pull current timer
    add d
    ld (hl), a                  ; set the timer
    jp @end


@checkTimer:
    ld hl, MusicTimers
    add hl, bc
    ld a, (hl)                  ; is there a counter?
    cp $00
    jr z, @note
    dec a                       ; lower counter
    ld (hl), a
    jp @nextChannel             ; and skip this music update

@note:
    ld a, c                     ; will skip freq if noise channel
    cp CHAN_NOISE
    jp z, @handleCh3

    ld a, d
    ; it's note
    and $F0                     ; just note
    swap a

    dec a                       ; entry 0 in LUT is C
    add a                       ; pitch LUT is 2 bytes per entry
    ld hl, Pitches
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    ldi a, (hl)                 ; get pitch value
    ld e, a
    ld a, (hl)
    ld b, a

    ; divide to get octave
    ld hl, MusicOctaves
    ld a, c
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    ld a, (hl)                  ; retrieve the octave
-   cp $00
    jr z, +
    sra b
    rr e
    dec a
    jr -
+

    ; store delay for note
    ld hl, MusicTimers
    ld a, c
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    ld a, d
    and $0F
    ld (hl), a


    ; handle note based on channel number
    ld a, c
    cp CHAN_PULSE1
    jr z, @handleCh0
    cp CHAN_PULSE2
    jr z, @handleCh1
    cp CHAN_WAVE
    jr z, @handleCh2

    jp @end                     ; if no handler, ignore it

@handleCh0:
    ld a, (SFXCurrent)          ; check if sfx are being played on this channel
    bit CHAN_PULSE1, a
    jr nz, @end

    ld a, (MusicVoices + 0)
    ldh (R_NR11), a
    ld a, (MusicVoices + 1)
    ldh (R_NR12), a
    ld a, e
    ldh (R_NR13), a
    ld a, %00000111             ; high 3 bit freq mask
    and b
    add %11000000               ; high bits to restart sound
    ldh (R_NR14), a
    jr @end

@handleCh1:
    ld a, (SFXCurrent)          ; check if sfx are being played on this channel
    bit CHAN_PULSE2, a
    jr nz, @end

    ld a, (MusicVoices + 2)
    ldh (R_NR21), a
    ld a, (MusicVoices + 3)
    ldh (R_NR22), a
    ld a, e
    ldh (R_NR23), a
    ld a, %00000111             ; high 3 bit freq mask
    and b
    add %11000000               ; high bits to restart sound
    ldh (R_NR24), a
    jr @end

@handleCh2:
    ld a, (SFXCurrent)          ; check if sfx are being played on this channel
    bit CHAN_WAVE, a
    jr nz, @end

    xor a
    ldh (R_NR30), a
    ld a, %10000000
    ldh (R_NR30), a
    ld a, (MusicVoices + 4)
    ldh (R_NR31), a
    ld a, (MusicVoices + 5)
    ldh (R_NR32), a
    ld a, e
    ldh (R_NR33), a
    ld a, %00000111
    and b
    add %11000000
    ldh (R_NR34), a
    jr @end

@handleCh3:
    ld a, (SFXCurrent)          ; check if sfx are being played on this channel
    bit CHAN_NOISE, a
    jr nz, @end

    ld hl, NoiseSamples
    ld e, d
    ld d, 0
    dec e
    srl d
    rl e
    add hl, de
    ldi a, (hl)
    ldh (R_NR42), a
    ld a, (hl)
    ldh (R_NR43), a
    ld a, %11000000
    ldh (R_NR44), a

@end:
    ld b, 0
    ld hl, MusicPointer
    add hl, bc
    add hl, bc
    ldi a, (hl)
    ld e, a
    ldd a, (hl)                 ; decrement hl for later storing music pointer
    ld d, a
    inc de                      ; increment music pointer
    ld a, e                     ; lower byte
    ldi (hl), a
    ld a, d                     ; upper byte
    ld (hl), a

@nextChannel:
    inc c
    ld a, NUM_MUSIC_CHANS
    cp c                        ; done with all channels?
    jp nz, @readSongData
    ret

.ENDS


.RAMSECTION "SFX Variables" BANK 0 SLOT 3
    SFXCurrent:         db              ; SFX currently playing on channels
    SFXPointer:         dsw APU_CHANNELS
    SFXTimers:          dsb APU_CHANNELS
.ENDS


.SECTION "SFX Subroutines" FREE

QueueSFX:
    ; Sets up a sound effect to play.
    ; hl    SFX address

    ; queue for specified channel
    ldi a, (hl)             ; get channel #
    ld c, a
    ld b, a
    ld a, $FF
    and b
    ld a, 1                 ; start with first bit
    jr z, +                 ; first channel check
-   sla a
    dec b
    jr nz, -
+   
    ld b, a
    ld a, (SFXCurrent)
    or b                    ; add to sfx queue
    ld (SFXCurrent), a      ; store sfx queue

    ; setup pointer
    ld de, SFXPointer
    ld a, c                 ; c is chan #
    sla a                   ; x2 for word length
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    ld a, l                 ; store in little endian
    ld (de), a
    inc de
    ld a, h
    ld (de), a

    ; setup timer
    ld de, SFXTimers
    ld a, c                 ; c is chan #
    add e
    ld e, a
    ld a, 0
    adc d
    ld d, a
    ld a, 1                 ; yes, all that to store just 1
    ld (de), a
    ret


HandleSFX:
    ; Takes care of playing sound effects.
    ; check if we need to handle any queued sfx
    ld a, (SFXCurrent)
    and %00001111
    ret z                   ; no sfx to handle

    bit 0, a                ; check channel 0 - Pulse 1
    jr z, @checkchan1

    ; check timer 
    ld de, SFXTimers
    ld a, (de)
    dec a
    ld (de), a
    jr nz, +
    
    ; load in new sfx data
    ld a, (SFXPointer)      ; get SFX pointer (little endian)
    ld l, a
    ld a, (SFXPointer+1)
    ld h, a
    ldi a, (hl)             ; get note data
    cp $FF                  ; if the first byte is $FF...
    jr nz, ++
    ld a, (SFXCurrent)      ;...channel 0 is done
    res 0, a
    ld (SFXCurrent), a
    jr +
++  ldh (R_NR10), a         ; store in sound registers
    ldi a, (hl)
    ldh (R_NR11), a
    ldi a, (hl)
    ldh (R_NR12), a
    ldi a, (hl)
    ldh (R_NR13), a
    ldi a, (hl)
    ldh (R_NR14), a
    ldi a, (hl)             ; get next timer
    ld de, SFXTimers
    ld (de), a              ; store timer
    ld e, l                 ; put address of music data in de...
    ld d, h
    ld hl, SFXPointer       ; ...to be stored here (little endian)
    ld a, e
    ldi (hl), a
    ld a, d
    ld (hl), a
+   ld a, (SFXCurrent)      ; will need this again for next check

@checkchan1:                ; check channel 1 - Pulse 2
    bit 1, a
    jr z, @checkchan2
    ; TODO

@checkchan2:                ; check channel 2 - Wave
    bit 2, a
    jr z, @checkchan3
    ; TODO

@checkchan3:                ; check channel 3 - Noise
    bit 3, a
    ret z

    ; check timer 
    ld de, SFXTimers+3
    ld a, (de)
    dec a
    ld (de), a
    ret nz
    
    ; load in new sfx data
    ld a, (SFXPointer+6)    ; get SFX pointer (little endian)
    ld l, a
    ld a, (SFXPointer+7)
    ld h, a
    ldi a, (hl)             ; get note data
    cp $FF                  ; if the first byte is $FF...
    jr nz, ++
    ld a, (SFXCurrent)      ;...channel 3 is done
    res 3, a
    ld (SFXCurrent), a
    ret
++  ldh (R_NR41), a         ; store in sound registers
    ldi a, (hl)
    ldh (R_NR42), a
    ldi a, (hl)
    ldh (R_NR43), a
    ldi a, (hl)
    ldh (R_NR44), a
    ldi a, (hl)             ; get next timer
    ld de, SFXTimers+3
    ld (de), a              ; store timer
    ld e, l                 ; put address of music data in de...
    ld d, h
    ld hl, SFXPointer+6     ; ...to be stored here (little endian)
    ld a, e
    ldi (hl), a
    ld a, d
    ld (hl), a
    ret

.ENDS


.SECTION "SFX" FREE

SFX_Pause:
.DB $00     ; Channel 0 - Pulse 1
;  NR10 NR11 NR12 NR13 NR14
.DB $00, $84, $F4, $90, $F7
.DB $05
.DB $00, $84, $F1, $B5, $F7
.DB $05
.DB $FF

SFX_Hit:
.DB $03     ; Channel 3 - Noise
;  NR41 NR42 NR43 MR44
.DB $FE, $F2, $80, $A0
.DB $05
.DB $FF

.ENDS

; vim: filetype=wla
