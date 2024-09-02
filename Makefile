# You can set the name of the .gb ROM file here
PROJECTNAME    	= TheGame
SRCDIR      	= src
LIBDIR      	= libs
OBJDIR      	= obj
DSTDIR      	= dist
RESDIR      	= $(SRCDIR)/resources
ASMDIR          = $(SRCDIR)/main
RESSPRITES      = $(RESDIR)/sprites
RESBACKGROUNDS  = $(RESDIR)/backgrounds
GENDIR	    	= $(SRCDIR)/generated
GENSPRITES	    = $(GENDIR)/sprites
GENBACKGROUNDS	= $(GENDIR)/backgrounds
BINS	    	= $(DSTDIR)/$(PROJECTNAME).gb
# Tools
RGBDS ?=
ASM := $(RGBDS)rgbasm
GFX := $(RGBDS)rgbgfx
LINK := $(RGBDS)rgblink
FIX := $(RGBDS)rgbfix

# Tool flags
ASMFLAGS := 
FIXFLAGS := -v -p 0xFF

# Make does not offer a recursive wild card function, so here's one:
rwildcard = $(foreach d,\
		$(wildcard $(1:=/*)), \
		$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d) \
	)

# This makes it so every entry in a space-delimited list appears only once
unique = $(if $1,\
			$(firstword $1) $(call unique,$(filter-out $(firstword $1),$1)) \
		)

# Collect ASM sources from ASMDIR and LIBDIR.
ASMSOURCES_COLLECTED = \
	$(call rwildcard,$(ASMDIR),*.asm) $(call rwildcard,$(LIBDIR),*.asm)

OBJS = $(patsubst %.asm,$(OBJDIR)/%.o,$(notdir $(ASMSOURCES_COLLECTED)))

all: $(BINS) #clean


NEEDED_GRAPHICS = \
	$(GENSPRITES)/TestPlayer.2bpp \
	$(GENSPRITES)/projectile.2bpp 

# $(GENBACKGROUNDS)/text-font.2bpp 
	



# Generate sprites, ensuring the containing directories have been created.
$(GENSPRITES)/%.2bpp: $(RESSPRITES)/%.png | $(GENSPRITES)
	$(GFX) --columns -o $@ $<

# Generate background tile set, ensuring the containing directories have been created.
$(GENBACKGROUNDS)/%.2bpp: $(RESBACKGROUNDS)/%.png | $(GENBACKGROUNDS)
	$(GFX) -o $@ $<

# Generate background tile map *and* tile set, ensuring the containing directories
# have been created.
$(GENBACKGROUNDS)/%.tilemap: $(RESBACKGROUNDS)/%.png | $(GENBACKGROUNDS)
	$(GFX) \
		--tilemap $@ \
		--unique-tiles \
		-o $(GENBACKGROUNDS)/$*.2bpp \
		$<

compile.bat: Makefile
	@echo "REM Automatically generated from Makefile" > compile.bat
	@make -sn | sed y/\\/\\\\/\\\\\\\^/ | grep -v make >> compile.bat


# Extract directories from collected ASM sources and append "%.asm" to each one,
# creating a wildcard-rule.
ASMSOURCES_DIRS = $(patsubst %,%%.asm,\
			$(call unique,$(dir $(ASMSOURCES_COLLECTED))) \
		)

# This is a Makefile "macro".
# It defines a %.o target from a corresponding %.asm, ensuring the
# "prepare" step has ran and the graphics are already generated.
define object-from-asm
$(OBJDIR)/%.o: $1 | $(OBJDIR) $(NEEDED_GRAPHICS)
	$$(ASM) $$(ASMFLAGS) -o $$@ $$<
endef

# Run the macro for each directory listed in ASMSOURCES_DIRS, thereby
# creating the appropriate targets.
$(foreach i, $(ASMSOURCES_DIRS), $(eval $(call object-from-asm,$i)))
# ANCHOR_END: generate-objects

# Link and build the final ROM.
$(BINS): $(OBJS) | $(DSTDIR)
	$(LINK) -o $@ $^
	$(FIX) $(FIXFLAGS) $@
# Ensure directories for generated files exist.
define ensure-directory
$1:
	mkdir -p $$@
endef

PREPARE_DIRECTORIES = \
	$(OBJDIR) $(GENSPRITES) $(GENBACKGROUNDS) $(DSTDIR)

$(foreach i, $(PREPARE_DIRECTORIES), $(eval $(call ensure-directory,$i)))

# Clean up generated directories.
clean:
	rm -rfv  $(PREPARE_DIRECTORIES)
# Declare these targets as "not actually files".
.PHONY: clean all



# Copy final game to emulator's games folder
ADDRWINDOWS=/mnt/c/Users/theoc/Coding/Perso/GameBoyExperimentation
copy: 
	cp $(DSTDIR)/$(PROJECTNAME).gb $(ADDRWINDOWS)