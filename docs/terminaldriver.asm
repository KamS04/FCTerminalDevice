data8 devId = { $00 }
data16 commBuff = { $00 }

;; r1 -> buffer
;; r2 -> length
write:
s_w:
    mov $0000, acu
    jeq r2, &[!end]
    mov $0000, r8          ;; cwr
    mov &[!commBuff], r7   ;; cBuff
s_f:
    mms $01
    mov8 &r1, r6
    mov8 r6, &r7
    mms $00
    inc r7                 ;; cBuff++
    inc r8                 ;; cwr++
    dec r2                 ;; length--
    inc r1                 ;; buffer++
    mov $0000, acu
    jeq r2, &[!e_f]
    mov $0031, acu
    jne r8, &[!s_f]
e_f:
    mov $0000, r7
    mov8 &[!devId], r8
    sig r8
    mov $0000, acu
    jne r2, &[!s_w]
end:
    rti

;; r1 -> buffer
;; r2 -> length
read:
w_o_s:
    mov &[!commBuff], r8          ;; note r8 = commBuff*
    mov $00f0, r7
    mms $01
    mov r7, &r8                   ;; setup_read_command
    mms $00
    mov &[!devId], r7
    sig r7                        ;; signal device
r_s:
    mms $01
    mov8 &r8, r6
    mms $00
    and r6, $80                   ;; acu = has_more
    mov acu, r5
    sub r5, r6                    ;; r5 = has_more
    mov acu, r6                   ;; r6 = read length
    mov $0000, acu
    jeq r6, &[!f_u]
    inc r8                        ;; commBuff moved to spot 1
w_b_s:
    mms $01
    mov8 &r8, r4
    mov8 r4, &r1                  ;; commBuff[i] -> buffer[i]
    mms $00
    inc r1                        ;; buffer moved to next spot
    inc r8                        ;; commuff moved to next stop
    dec r6                        ;; decrement read length
    dec r2                        ;; decrement total_length
    mov $0000, acu
    jeq r2, &[!f_u]               ;; if completely_done -> finish_up
    jne r6, &[!w_b_s]             ;; jump to start of loop
w_b_f:
f_u: ;; reader still has stuff
    mov $0000, acu
    jeq r5, &[!w_o_c]             ;; clearing devices buffer
    mov &[!commBuff], r8
    mov $00f0, r6
    mms $01
    mov r6, &r8
    sig r7
    mov8 &r8, r6
    and r6, $80
    mms $00
    mov [!f_u], r8
    rav r8, r8
    mov r8, ip                    ;; jmp
w_o_c: ;; reading done nothing to clean up
    rti
