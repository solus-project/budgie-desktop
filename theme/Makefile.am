EXTRA_DIST = \
	budgie-theme.gresource.xml \
	.nvmrc \
	assets.svg \
	assets.txt \
	gulpfile.js \
	package.json \
	README.md \
	render-assets.sh \
	theme.css \
	theme_hc.css \
	assets/checkbox.png \
	assets/checkbox@2.png \
	assets/checkbox-active.png \
	assets/checkbox-active@2.png \
	assets/radio.png \
	assets/radio@2.png \
	assets/radio-active.png \
	assets/radio-active@2.png \
	assets/switch.png \
	assets/switch@2.png \
	assets/switch-active.png \
	assets/switch-active@2.png \
	assets/switch-hc.png \
	assets/switch-hc@2.png \
	assets/switch-active-hc.png \
	assets/switch-active-hc@2.png \
	assets/scale-slider.png \
	assets/scale-slider@2.png \
	sass/_colors.scss \
	sass/_drawing.scss \
	sass/_main.scss \
	sass/theme.scss \
	sass/theme_hc.scss \
	theme.vapi

panel_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/theme --generate-dependencies $(top_srcdir)/theme/budgie-theme.gresource.xml)

BUILT_SOURCES = \
	budgie-theme-resources.h \
	budgie-theme-resources.c


# resources
budgie-theme-resources.h: $(top_srcdir)/theme/budgie-theme.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/theme --generate-header --c-name budgie_desktop_theme $<

budgie-theme-resources.c: $(top_srcdir)/theme/budgie-theme.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/theme --generate-source --c-name budgie_desktop_theme $<

lib_LTLIBRARIES = \
	libbudgietheme.la

libbudgietheme_la_SOURCES = \
	budgie-theme-resources.h \
	budgie-theme-resources.c \
	theme.h \
	theme.c

libbudgietheme_la_CFLAGS = \
	$(BUDGIE_BASE_CFLAGS)
