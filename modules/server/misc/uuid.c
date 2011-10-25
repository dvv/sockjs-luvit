#include <stdint.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/syscall.h>
#include <fcntl.h>

//
// Vladimir Dronnikov, <dronnikov@gmail.com>, 2011
//

// thanks BusyBox
// TODO: what about MS Windows?

void uuid(uint8_t *buf)
{
	pid_t pid;
	int i;
	i = open("/dev/urandom", O_RDONLY);
	if (i >= 0) {
		read(i, buf, 16);
		close(i);
	}
	struct timespec ts;
	syscall(SYS_clock_gettime, 1, &ts);
	srand(ts.tv_sec * 1000000ULL + ts.tv_nsec/1000);
	pid = getpid();
	while (1) {
		for (i = 0; i < 16; i++)
			buf[i] ^= rand() >> 5;
		if (pid == 0)
			break;
		srand(pid);
		pid = 0;
	}
	buf[4 + 2    ] = (buf[4 + 2    ] & 0x0f) | 0x40;
	buf[4 + 2 + 2] = (buf[4 + 2 + 2] & 0x3f) | 0x80;
}
