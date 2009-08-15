BEGIN {
	if (!(lib || lib_r)) {
		print "Not normal, neither threads-safe " \
			"mode" >"/dev/stderr"
		errs++
	}

	vfile = "lib/version"
	if ((getline version <vfile) <= 0) {
		print vfile ": " ERRNO >"/dev/stderr"
		errs++
	}
	if (errs)
		exit(1)

	close(vfile)
	OFS = " "
	print "AWK_INCLUDE =", awkincl
	print "SQL_INCLUDE =", sqlincl
	if (!prefix)
		prefix = "/usr/lib/"
	else if (prefix !~ /\/$/)
		prefix = prefix "/"

	print "PREFIX =", prefix
	if (lib)
		print "LIB =", lib

	if (lib_r)
		print "LIB_r =", lib_r

	print "OBJ = spawk.o"
	print "BU_LIST = README INSTALL configure tools/*.sh " \
		"src.stable/*.c src/*.c lib/* bin/* Test/* Sample/*"

	print ""
	print ".SUFFIXES:"
	print ""

	printf "all: Makefile"
	if (lib)
		printf " $(LIB)"

	if (lib_r)
		printf " $(LIB_r)"

	print ""
	print ""
	print "Makefile: lib/version"
        print "\t@echo \"Run \\`sh configure' to refresh \\`Makefile'\""
	print "\t@exit 1"

	if (lib) {
		print ""
		print "$(LIB): $(OBJ)"
		print "\t@sh tools/makelib.sh $(LIB)", sqllib
	}

	if (lib_r) {
		print ""
		print "$(LIB_r): $(OBJ)"
		print "\t@sh tools/makelib.sh $(LIB_r)", sqllib_r
	}

	print ""
	print "$(OBJ): spawk.c"
	print "\t@sh tools/checkincl.sh $(AWK_INCLUDE) awk.h"
	print "\t@sh tools/checkincl.sh $(SQL_INCLUDE) mysql.h"
	print "\t@echo \"Compiling \\`spawk.c'...\""
	print "\t@gcc -shared -g -c -O -I$(AWK_INCLUDE) " \
		"-I$(SQL_INCLUDE) -D_SPAWK_DEBUG " \
		"-DHAVE_CONFIG_H -DSPAWK_VERSION=\"\\\"" \
		version "\\\"\" spawk.c"
	print "\t@strip --strip-unneeded $(OBJ)"

	print ""
	printf "install:"
	if (lib)
		printf " $(PREFIX)$(LIB)"

	if (lib_r)
		printf " $(PREFIX)$(LIB_r)"

	print ""
	if (lib) {
		print ""
		print "$(PREFIX)$(LIB): $(OBJ)"
		print "\t@mv $(LIB) $(PREFIX)$(LIB)"
		print "\t@sh tools/makelib.sh $(PREFIX)$(LIB)"
	}

	if (lib_r) {
		print ""
		print "$(PREFIX)$(LIB_r): $(OBJ)"
		print "\t@mv $(LIB_r) $(PREFIX)$(LIB_r)"
		print "\t@sh tools/makelib.sh $(PREFIX)$(LIB_r)"
	}

	print ""
	print "test:"
	print "\t@make"
	print "\t@-LD_LIBRARY_PATH=\".\" awk -f Test/test99.awk 2>error"
	print "\t@[ -s error ] && cat error >&2; rm -f error"

	print ""
	print "cleanup:"
	printf "\t@rm -f backup spawk.* spawk*.tar"
	if (lib)
		printf " $(LIB)"

	if (lib_r)
		printf " $(LIB_r)"

	print ""
	print ""
	print "cleanall:"
	print "\t@make cleanup"
	printf "\t@rm -f"
	if (lib)
		printf " $(PREFIX)$(LIB)"

	if (lib_r)
		printf " $(PREFIX)$(LIB_r)"

	print ""
	print ""
	print "backup: spawk" version ".tar"
	print "\t@sh tools/backup.sh " version

	print ""
	print "commit: spawk" version ".tar"
	print "\t@sh tools/commit.sh " version

	print ""
	print "spawk" version ".tar: $(BU_LIST)"
	print "\t@make all"
	print "\t@tar -czvf spawk" version ".tar $(BU_LIST) >spawk.lst"

	print ""
	print "spawk.c: src.stable/*.c src/*.c"
	print "\t@sh tools/makesrc.sh >spawk.c"
	print "\t@sh tools/makeprn.sh >spawk.txt"

	print ""
	print "man:"
	print "\t@groff -T ascii -man -rLL=6.5i -rLT=7.7i " \
		"lib/spawk.man | less -is"

	exit(0)
}