ifeq ($(strip $(PRODUCT_NAME)),)
PRODUCT_NAME:=impdclient
endif
ifeq ($(strip $(SRCROOT)),)
SRCROOT=.
endif
ifeq ($(strip $(BUILT_PRODUCTS_DIR)),)
BUILT_PRODUCTS_DIR=./build/Debug
endif
ifeq ($(strip $(CONFIGURATION_TEMP_DIR)),)
CONFIGURATION_TEMP_DIR=./build/impdclient.build/Debug
endif

INFOPLIST=Info.plist
DEFAULT_BACKGROUND=Default.png
APP_ICON=icon.png
SOURCES=\
	main.m \
	impdclientApp.m \
	AlbumsView.m \
	ArtistsView.m \
	PlaylistView.m \
	PreferencesView.m \
	SearchView.m \
	SongsView.m

FRAMEWORKS=\
    -framework CoreFoundation \
    -framework Foundation \
    -framework UIKit \
    -framework CoreGraphics \
    -framework GraphicsServices \
    -framework LayerKit

CC=/usr/local/bin/arm-apple-darwin-gcc
CFLAGS=-O3 -g -Wall -I/usr/local/arm-apple-darwin/include -I/usr/local/arm-apple-darwin/include/Foundation
LD=$(CC)
LDFLAGS=-lobjc $(FRAMEWORKS) libmpd.a

WRAPPER_NAME=$(PRODUCT_NAME).app
EXECUTABLE_NAME=$(PRODUCT_NAME)
SOURCES_ABS=$(addprefix $(SRCROOT)/,$(SOURCES))
INFOPLIST_ABS=$(addprefix $(SRCROOT)/,$(INFOPLIST))
DEFAULT_BACKGROUND_ABS=$(addprefix $(SRCROOT)/,$(DEFAULT_BACKGROUND))
APP_ICON_ABS=$(addprefix $(SRCROOT)/,$(APP_ICON))
OBJECTS=\
	$(patsubst %.c,%.o,$(filter %.c,$(SOURCES))) \
	$(patsubst %.cc,%.o,$(filter %.cc,$(SOURCES))) \
	$(patsubst %.cpp,%.o,$(filter %.cpp,$(SOURCES))) \
	$(patsubst %.m,%.o,$(filter %.m,$(SOURCES))) \
	$(patsubst %.mm,%.o,$(filter %.mm,$(SOURCES)))
OBJECTS_ABS=$(addprefix $(CONFIGURATION_TEMP_DIR)/,$(OBJECTS))
APP_ABS=$(BUILT_PRODUCTS_DIR)/$(WRAPPER_NAME)
PRODUCT_ABS=$(APP_ABS)/$(EXECUTABLE_NAME)

all: $(PRODUCT_ABS)

$(PRODUCT_ABS): $(APP_ABS) $(OBJECTS_ABS)
	$(LD) $(LDFLAGS) -o $(PRODUCT_ABS) $(OBJECTS_ABS)

$(APP_ABS): $(INFOPLIST_ABS)
	mkdir -p $(APP_ABS)
	cp $(INFOPLIST_ABS) $(APP_ABS)/
	cp $(DEFAULT_BACKGROUND_ABS) $(APP_ABS)/
	cp $(APP_ICON_ABS) $(APP_ABS)/

$(CONFIGURATION_TEMP_DIR)/%.o: $(SRCROOT)/%.m
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS_ABS)
	rm -rf $(APP_ABS)

