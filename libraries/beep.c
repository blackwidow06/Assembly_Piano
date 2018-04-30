/*  beep - just what it sounds like, makes the console beep - but with
 * precision control.  See the man page for details.
 *
 * Try beep -h for command line args
 *
 * This code is copyright (C) Johnathan Nightingale, 2000.
 *
 * This code may distributed only under the terms of the GNU Public License 
 * which can be found at http://www.gnu.org/copyleft or in the file COPYING 
 * supplied with this code.
 *
 * This code is not distributed with warranties of any kind, including implied
 * warranties of merchantability or fitness for a particular use or ability to 
 * breed pandas in captivity, it just can't be done.
 *
 * Bug me, I like it:  http://johnath.com/  or johnath@johnath.com
 */

#include <fcntl.h>
#include <getopt.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <linux/kd.h>
#include <linux/input.h>

#ifndef CLOCK_TICK_RATE
#define CLOCK_TICK_RATE 1193180
#endif

/*  CREDIT TO...
#define VERSION_STRING "beep-1.3"
char *copyright =
"Copyright (C) Johnathan Nightingale, 2002.  "
"Use and Distribution subject to GPL.  "
"For information: http://www.gnu.org/copyleft/.";
*/

/* Meaningful Defaults */
#define DEFAULT_FREQ       440.0 /* Middle A */
#define DEFAULT_LENGTH     200   /* milliseconds */
#define DEFAULT_REPS       1
#define DEFAULT_DELAY      100   /* milliseconds */
#define DEFAULT_END_DELAY  NO_END_DELAY
#define DEFAULT_STDIN_BEEP NO_STDIN_BEEP

/* Other Constants */
#define NO_END_DELAY    0
#define YES_END_DELAY   1

#define NO_STDIN_BEEP   0
#define LINE_STDIN_BEEP 1
#define CHAR_STDIN_BEEP 2

typedef struct beep_parms_t {
  float freq;     /* tone frequency (Hz)      */
  int length;     /* tone length    (ms)      */
  int reps;       /* # of repetitions         */
  int delay;      /* delay between reps  (ms) */
  int end_delay;  /* do we delay after last rep? */
  int stdin_beep; /* are we using stdin triggers?  We have three options:
		     - just beep and terminate (default)
		     - beep after a line of input
		     - beep after a character of input
		     In the latter two cases, pass the text back out again,
		     so that beep can be tucked appropriately into a text-
		     processing pipe.
		  */
  int verbose;    /* verbose output?          */
  struct beep_parms_t *next;  /* in case -n/--new is used. */
} beep_parms_t;

enum { BEEP_TYPE_CONSOLE, BEEP_TYPE_EVDEV };

/* Momma taught me never to use globals, but we need something the signal 
   handlers can get at.*/
int console_fd = -1;
int console_type = BEEP_TYPE_CONSOLE;
char *console_device = NULL;


void do_beep(int freq) {
  int period = (freq != 0 ? (int)(CLOCK_TICK_RATE/freq) : freq);

  if(console_type == BEEP_TYPE_CONSOLE) {
    if(ioctl(console_fd, KIOCSOUND, period) < 0) {
      putchar('\a');  /* Output the only beep we can, in an effort to fall back on usefulness */
      perror("ioctl");
    }
  } else {
     /* BEEP_TYPE_EVDEV */
     struct input_event e;

     e.type = EV_SND;
     e.code = SND_TONE;
     e.value = freq;

     if(write(console_fd, &e, sizeof(struct input_event)) < 0) {
       putchar('\a'); /* See above */
       perror("write");
     }
  }
}


/* If we get interrupted, it would be nice to not leave the speaker beeping in
   perpetuity. */
void handle_signal(int signum) {

  if(console_device)
    free(console_device);

  switch(signum) {
  case SIGINT:
  case SIGTERM:
    if(console_fd >= 0) {
      /* Kill the sound, quit gracefully */
      do_beep(0);
      close(console_fd);
      exit(signum);
    } else {
      /* Just quit gracefully */
      exit(signum);
    }
  }
}

void play_beep(beep_parms_t parms) {
  int i; /* loop counter */

  if(parms.verbose == 1)
      fprintf(stderr, "[DEBUG] %d times %d ms beeps (%d delay between, "
	"%d delay after) @ %.2f Hz\n",
	parms.reps, parms.length, parms.delay, parms.end_delay, parms.freq);

  /* try to snag the console */
  if(console_device)
    console_fd = open(console_device, O_WRONLY);
  else
    if((console_fd = open("/dev/tty0", O_WRONLY)) == -1)
      console_fd = open("/dev/vc/0", O_WRONLY);

  if(console_fd == -1) {
    fprintf(stderr, "Could not open %s for writing\n",
      console_device != NULL ? console_device : "/dev/tty0 or /dev/vc/0");
    printf("\a");  /* Output the only beep we can, in an effort to fall back on usefulness */
    perror("open");
    exit(1);
  }

  if (ioctl(console_fd, EVIOCGSND(0)) != -1)
    console_type = BEEP_TYPE_EVDEV;
  else
    console_type = BEEP_TYPE_CONSOLE;
  
  /* Beep */
  for (i = 0; i < parms.reps; i++) {                    /* start beep */
    do_beep(parms.freq);
    /* Look ma, I'm not ansi C compatible! */
    usleep(1000*parms.length);                          /* wait...    */
    do_beep(0);                                         /* stop beep  */
    if(parms.end_delay || (i+1 < parms.reps))
       usleep(1000*parms.delay);                        /* wait...    */
  }                                                     /* repeat.    */

  close(console_fd);
}

int beep(int freq, int duration) {

	beep_parms_t *parms = (beep_parms_t *)malloc(sizeof(beep_parms_t));

	parms->freq = freq;
	parms->length = duration;
	parms->reps = DEFAULT_REPS;
	parms->delay = DEFAULT_DELAY;
	parms->end_delay = DEFAULT_END_DELAY;
	parms->stdin_beep = DEFAULT_STDIN_BEEP;
	parms->verbose = 0;
	parms->next = NULL;

	play_beep(*parms);

	free(parms);

	return 0;

}
