data8 devId = { $00 }
data16 commBuff = { $0000 }
data8 toFlush = { $00 }

constant READ_S = $00
constant WRITE_S = $01
constant FLUSH_S = $02
constant POPBACK_S = $03
constant POPNEXT_S = $04

constant I_WRITE = $01
constant I_READ = $02
constant I_FLUSH = $03

;; r1 <- function
;; [r2 <- buffer]
;; [r3 <- length]
;; [r4 <- use_old]
td_interrupt:
    mov r1, acu
    jeq [!I_WRITE], &[!write]
    jeq [!I_READ], &[!read]
    jeq [!I_FLUSH], &[!flush]
    mov $00, acu
    rti


;; r2 <- buffer
;; r3 <- length
write:
    mov $00, acu
    jle r3, &[!write_end]
    mov &[!commBuff], r4 ;; r4 <- commBuff
    mov [!WRITE_S], acu
    mms $01
    mov8 acu, &r4
    mms $00
    mov r3, r5           ;; r5 <- to_move
    mov $30, acu
    jle r5, &[!write_size]
    mov $30, r5
write_size:
    inc r4
    movb r2, r4, r5
    sub r3, r5
    mov acu, r3
    add r2, r5
    mov acu, r2
    add r4, r5
    mov $00, r5
    mms $01
    mov r5, &acu
    mms $00
    mov8 &[!devId], acu
    sig acu
    jmp &[!write]
write_end:
    rti

structure ReadV {
    buffer: $02,
    totalLength: $02,
    useOld: $01,
    hasMore: $01,
    readLength: $02,
    leftLength: $02,
    size: $00
}

;; r2 <- buffer
;; r3 <- length
;; r4 <- use_old
read:
    sub sp, [<ReadV>$0.size]
    mov acu, sp            ;; wooooo finally using the bloody stack
    mov r2, &sp
    add [<ReadV>$0.totalLength], sp
    mov r3, &acu
    add [<ReadV>$0.useOld], sp
    mov8 r4, &acu
    add [<ReadV>$0.readLength], sp
    mov $00, r1
    mov r1, &acu
    mov $00, acu
    jle r3, &[!read_end]
    
    mov8 &[!toFlush], acu
    jeq $00, &[!read_s]
    mov $00, acu
    jne r4, &[!read_s]
    mov8 &[!toFlush], acu    ;; do I really need to recopy flush
    mov [!FLUSH_S], acu
    mov &[!commBuff], r1
    mms $01
    mov8 acu, &r1
    mms $00
    mov8 &[!devId], acu
    sig acu

read_s:
    mov &[!commBuff], r1
    mov8 &[!toFlush], acu
    jeq $00, &[!read_s1]
    mov [!POPNEXT_S], acu
    mms $01
    mov acu, &r1
    mms $00
    jmp &[!read_s2]
read_s1:
    mov [!READ_S], acu
    mms $01
    mov acu, &r1
    mms $00
read_s2:
    mov8 &[!devId], r1
    sig r1
    add [<ReadV>$0.hasMore], sp
    mov &[!commBuff], r1
    mms $01
    mov8 &r1, r2
    mms $00
    mov r2, &acu
    inc r1
    add [<ReadV>$0.readLength], sp
    mms $01
    mov &r1, r2
    mms $00
    mov r2, &acu
    add [<ReadV>$0.leftLength], sp
    mov r2, &acu

read_w:
    mov [<ReadV>$0.leftLength], &sp, r3    ;; r3 <- move_length
    mov [<ReadV>$0.hasMore], &sp, r2
    rsf r2, $08
    jeq $00, &[!read_w_big_if]
    mov $2f, r3
read_w_big_if:
    mov [<ReadV>$0.totalLength], &sp, acu
    jgt r3, &[!read_w_big_else]
    mov acu, r1
    mov &[!commBuff], r1
    add $03, r1
    mov acu, r1
    mov [<ReadV>$0.buffer], &sp, r2
    movb r1, r2, r3
    mov r1, r2
    add r1, r3
    mov acu, r1
    sub $2f, r3
    movb r1, r2, acu
    mov acu, r4
    mov &[!commBuff], r1
    mov [!POPBACK_S], r2
    mms $01
    mov8 r2, &r1
    mms $00
    add $01, r1
    mov r4, &acu
    mov [<ReadV>$0.buffer], &sp, r2
    add r3, r2
    mov acu, r3
    add [<ReadV>$0.buffer], sp
    mov r3, &acu
    jmp &[!read_w_big_end]
read_w_big_else:
    mov &[!commBuff], r1
    mov [<ReadV>$0.buffer], &sp, r2
    movb r1, r2, r3
    add r2, r3
    mov acu, r2
    add [<ReadV>$0.buffer], sp
    mov r2, &acu
    mov [<ReadV>$0.totalLength], &sp, r1
    sub r1, r3
    mov acu, r1
    add [<ReadV>$0.totalLength], sp
    mov r1, &acu

read_w_big_end:
    mov [<ReadV>$0.totalLength], &sp, acu
    jeq $00, &[!read_w_end]
    mov [<ReadV>$0.hasMore], &sp, acu
    rsf acu, $08
    jeq $00, &[!read_w_end]

read_w_last:
    mov &[!commBuff], r1
    mov [!POPNEXT_S], r2
    mms $01
    mov8 r2, &r1
    mms $00
    mov8 &[!devId], r2
    sig r2
    add [<ReadV>$0.hasMore], sp
    mov8 &r1, r2
    mov r2, &acu
    inc r1
    mov &r1, r2
    add [<ReadV>$0.leftLength], sp
    mov r2, &acu
    jmp &[!read_w]

read_w_end:
    mov [<ReadV>$0.buffer], &sp, r1
    mov $00, acu
    mov8 acu, &r1

read_end:
    mov [<ReadV>$0.readLength], &sp, r1
    add [<ReadV>$0.size], sp
    mov acu, sp
    mov r1, acu
    rti


flush:
    mov8 &[!toFlush], acu
    jeq $00, &[!flush_end]
    mov [!FLUSH_S], acu
    mov &[!commBuff], r1
    mms $01
    mov acu, &r1
    mms $00
    mov8 &[!devId], acu
    sig acu
flush_end:
    rti