# dscli.el — build & maintenance targets
#
# .elc files are local build artifacts (gitignored).  Emacs prefers
# loading .elc over .el, so a stale .elc silently shadows newer source.
# Always run `make compile` after editing any .el file.

.PHONY: compile clean

# Byte-compile all source files (modules first so `require` resolves
# against freshly compiled artifacts when compiling the entry point).
compile:
	emacs -Q --batch -L . -L dscli-modules \
	  -f batch-byte-compile dscli-modules/*.el dscli.el

# Remove all compiled artifacts.
clean:
	find . -name '*.elc' -delete
