/* commons_b.c -- the LARGE twin of commons_a.c's shared_buf common.
** See commons_a.c for the build line.
*/

int shared_buf[16];

void fill_buf(void) {
    int i = 0;
    for (; i < 16; i++) shared_buf[i] = i + 1;   /* sum 136, 64 bytes written */
}
