# dscli.el — build & maintenance targets
#
# .elc files are local build artifacts (gitignored).  Emacs prefers
# loading .elc over .el, so a stale .elc silently shadows newer source.
# Always run `make compile` after editing any .el file.

.PHONY: compile clean

# Byte-compile in two passes: modules first, then entry point.  A single
# pass compiles dscli-main.el before later modules (alphabetical order),
# so its `require's would load stale .elc from previous builds.
compile:
	emacs -Q --batch -L . -L dscli-modules \
	  -f batch-byte-compile $$(ls dscli-modules/*.el | grep -v dscli-main.el)
	emacs -Q --batch -L . -L dscli-modules \
	  -f batch-byte-compile dscli-modules/dscli-main.el dscli.el

# Remove all compiled artifacts.
clean:
	find . -name '*.elc' -delete
