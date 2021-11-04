;==============================================================================
; GAME ROUTINES
;==============================================================================

.INCLUDE "gb_hardware.i"
.INCLUDE "header.i"


.SECTION "Game Routines" FREE

HandleGameInput:
    ; Key Down
    ldh a, (<joypadDiff)
    ld b, a		    ; store for later
    and JOY_RIGHT
    jr z, @checkleft
    ; Right
    ld a, (player.velx)
    add 2
    ld (player.velx), a
@checkleft:
    ld a, b
    and JOY_LEFT
    jr z, @checkdown
    ; Left
    ld a, (player.velx)
    sub 2
    ld (player.velx), a
@checkdown:
@checka:
@checkB:
    ld a, b
    and JOY_B
    jr z, @handledkeydowns
    ; B
    ld a, (player.velx)
    ld c, a
    cp 0		    ; test if 0 already
    jr nz, +
    jr ++
+   bit 7, a
    jr z, +
    inc a		    ; - velocities need to be increased
    jr ++
+   dec a		    ; + velocities need to be decreased
++  ld (player.velx), a
@handledkeydowns:

    ; Key Held
    ldh a, (<joypadNew)
    ;ld b, a		    ; store for later keypad checks
    and JOY_DOWN
    jr z, @handledkeyhelds
    ld a, (depth)
    ld b, a		    ; store for later score increment check
    add 1
    ld c, a		    ; store for later score increment check
    ld (depth), a
    jr nc, +
    ld a, (depth+1)	    ; increase high byte if carry
    inc a
    ld (depth+1), a
+
    ld a, b
    xor c		    ; only increment score if bit 4 changed
    and 16
    jr z, @noincscore
    ; increment score
    ld a, (score)
    add 1
    daa
    ld (score), a
    jr nc, +		    ; may need to handle carry
    ld a, (score+1)
    add 1
    daa
    ld (score+1), a
+

    ld a, 2
    ld (pendingdraw), a
@noincscore:

@handledkeyhelds:
    ret


ApplyVelX:
    ldh a, (<ticks)
    and $01
    jr nz, @applyvxend
    ld a, (player.velx)
    ld b, a
    bit 7, a		    ; is it negative?
    jr z, @movingright
    ; moving left
    ld a, b		    ; need to negate 2's compl velx
    cpl			    ; it's negative and we don't need it like that
    inc a		    ; to be subtracted from the x ord.
    ld b, a
    ld a, (player.x)
    sub b
    ld (player.x), a
    jr @applyvxend
@movingright:		    ; or even stationary (vel = 0)
			    ; no need to negate 2's compl. velx here
    ld a, (player.x)
    add b
    ld (player.x), a
@applyvxend:
    ret


SlowPlayerVel:
    ldh a, (<ticks)
    and $03
    jr nz, @noslow
    ld a, (player.x)
    cp (160/2)-8
    jr z, @noslow
    jr c, @lefthalf
    ; right half, left vel
    ; right half, right vel
    ld a, (player.velx)
    dec a
    ld (player.velx), a
    jr @noslow
@lefthalf:
    ; left half, right vel
    ; left half, left vel
    ld a, (player.velx)
    inc a
    ld (player.velx), a
++

    ld a, (player.velx)
    ld (player.velx), a
@noslow:
    ret


SetPlayerY:
    ; set player's y based off of the arc data
    ld a, (player.x)
    ld b, a
    ld hl, ArcData
    add l
    ld l, a
    ld a, 0
    adc h
    ld h, a
    ld a, (hl)
    ld c, a
    ld (player.y), a
    xor a
    call ObjMove
    ret


CheckWallCollision:
    ld a, (player.x)		    ; check if player hit the walls
    cp 160
    ret

.ENDS

; vim: filetype=wla
