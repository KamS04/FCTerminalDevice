char devId;
char *commBuff;

void signal(char id);
void movblock(void *from, void *to, short length);

void write() {
    char *buffer;
    short length;

    while (length > 0) {
        short to_move = length;
        if (length > 49) {
            to_move = 49;
        }
        movblock(buffer, commBuff, to_move);
        length -= to_move;
        buffer += to_move;
        *(commBuff+to_move) = '\0';
        signal(devId);
    }
    return;
}

void read() {
    char *buffer;
    short length;

    *commBuff = 0x01;
    signal(devId);

    short ret = *commBuff;

    short has_more = ret & 0x80;
    short read_length = ret - has_more;
    if (read_length == 0) {
        return;
    }

    char *cBuff = commBuff+1;
    do {
        *buffer = *cBuff;
        buffer++;
        cBuff++;
        read_length--;
        length--;
    } while (length != 0 && read_length != 0);

    do {
        if (has_more == 0) {
            break;
        }

        cBuff = commBuff;
        *cBuff = 0xf0;
        signal(devId);
        ret = *cBuff;
    } while (ret & 0x80);

    return;
}
