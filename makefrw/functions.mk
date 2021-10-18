#--------------------------------------------------------
# CUSTOM FUNCTIONS LIBRARY
# Note: No Need to change them
#--------------------------------------------------------

# lc: to lower case
lc = $(shell echo "$(1)" | tr '[:upper:]' '[:lower:]')
get_git_version = $(shell git -C $(1) describe --abbrev=4 --dirty --always --tags)
