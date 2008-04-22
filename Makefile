CC=/usr/local/bin/arm-apple-darwin-gcc
CFLAGS=-Wall

LD=$(CC)
LDFLAGS = -framework CoreFoundation \
          -framework Foundation \
          -framework UIKit \
          -framework LayerKit \
          -framework CoreGraphics \
          -framework GraphicsServices \
          -framework CoreSurface \
          -lobjc

all:	impdclient

impdclient:	main.o application.o PlaylistView.o ArtistsView.o AlbumsView.o SongsView.o SearchView.o
	$(LD) $(LDFLAGS) libmpd.a -o $@ $^

%.o:	%.m
		$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
		rm -f *.o *~ impdclient

