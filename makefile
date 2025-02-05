# ----------------------------
# Makefile Options
# ----------------------------

NAME = TiChess
ICON = icon.png
DESCRIPTION = "Chess Engine & AI"
COMPRESSED = NO
ARCHIVED = NO

HAS_PRINTF = NO

CFLAGS = -Wall -Wextra -O3
CXXFLAGS = -Wall -Wextra -O3

# ----------------------------

include $(shell cedev-config --makefile)
