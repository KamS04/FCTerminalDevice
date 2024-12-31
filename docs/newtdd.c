char devId;
char *commBuff;
char to_flush = 0;

void signal(char id);
void movblock(void *from, void *to, short length);

#define READ__S (0x00)
#define WRITE_S (0x01)
#define FLUSH_S (0x02)
#define POPBACK_S (0x03)
#define POPNEXT_S (0x04)

short td_interrupt(int a) {
    switch (a) {
        case 01:
            return write();
        case 02:
            return read();
        case 03:
            return flush_read();
        default:
            return 0;
    }
}

// r2 <- buffer
// r3 <- length
short write() {
    char *buffer;
    short length;

    while (length > 0) {
        *commBuff = READ__S;
        short to_move = length;
        if (length > 48) {
            to_move = 48;
        }
        movblock(buffer, commBuff+1, to_move);
        length -= to_move;
        buffer += to_move;
        *(commBuff+1+to_move) = '\0';
        signal(devId);
    }
    return 0;
}

// buffer should be length long with an extra space for a \0 character
// r2 <- buffer
// r3 <- length
// r4 <- use_old
int read() {
    char *buffer;
    short total_length;
    short use_old;

    char has_more;
    short read_length;
    short left_length;

    if (total_length <= 0) {
        return;
    }

    if (to_flush && !use_old) {
        flush();
    }

    if (to_flush) {
        *commBuff = POPNEXT_S;
    } else {
        *commBuff = WRITE_S;
    }
    signal(devId);
    has_more = *commBuff;
    read_length = *(short*)(commBuff+1);
    left_length = read_length;


    while (1) {
        short move_length = left_length;
        if (has_more) { // has more
            move_length = 47;
        }
        if (total_length < move_length) {
            move_length = total_length;
            movblock(commBuff+3,buffer,move_length);
            // Buffer back the rest
            movblock(commBuff+3+move_length,commBuff+3,47-move_length);
            *commBuff = POPBACK_S;
            *(short*)(commBuff+1) = 47-move_length;
            buffer = buffer+move_length;
            break;
        } else {
            movblock(commBuff+3, buffer, move_length);
            buffer = buffer + move_length;
            total_length = total_length - move_length;
        }

        if (total_length == 0 || !has_more) {
            break;
        }

        *commBuff = POPNEXT_S;
        signal(devId);
        has_more = *commBuff;
        left_length = *(short*)(commBuff+1);
        continue;
    }
    *buffer = '\0';
    return read_length;
}

void flush() {
    if (to_flush) {
        *commBuff = FLUSH_S;
        signal(devId);
    }
}
