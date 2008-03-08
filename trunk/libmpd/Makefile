CC=/usr/local/bin/arm-apple-darwin-gcc
AR=/usr/local/bin/arm-apple-darwin-ar
RANLIB=/usr/local/bin/arm-apple-darwin-ranlib

OBJS=libmpd.o libmpd-player.o libmpd-status.o libmpd-playlist.o libmpdclient.o \
	libmpd-strfsong.o libmpd-database.o debug_printf.o

all:	../libmpd.a

../libmpd.a: $(OBJS)
	$(AR) cq ../libmpd.a $(OBJS)
	$(RANLIB) ../libmpd.a
	

%.o:	%.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
	rm -f *.o
		