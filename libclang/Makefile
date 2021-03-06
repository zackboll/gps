TMP_GEN_DIR=gen
CLANG_RELEASE=3.7.1
CLANG_SRC_DIR=cfe-$(CLANG_RELEASE).src
CLANG_INCLUDE_DIR=$(shell pwd)/$(CLANG_SRC_DIR)/include
CLANG_INCLUDE_DIR_C=$(CLANG_INCLUDE_DIR)/clang-c
DL=wget
CLANG_SRC_FNAME=$(CLANG_SRC_DIR).tar.xz
CLANG_SRC_LINK=http://llvm.org/releases/$(CLANG_RELEASE)/$(CLANG_SRC_FNAME)

ifeq ($(wildcard binding/clang.ads),)
all: clean_imports
else
all:
endif

init: init_gen init_clang_src

init_gen:
	mkdir -p $(TMP_GEN_DIR)

init_clang_src:
	if [ ! -d $(CLANG_SRC_DIR) ]; then $(DL) $(CLANG_SRC_LINK) && tar xvf $(CLANG_SRC_FNAME) && rm $(CLANG_SRC_FNAME); fi

generate_fdump_bindings: init
	cd $(TMP_GEN_DIR) && g++ -I/usr/include/x86_64-linux-gnu -I$(CLANG_INCLUDE_DIR) -DNDEBUG -D_GNU_SOURCE -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS -U__cplusplus -c -D_Bool=bool -fdump-ada-spec $(CLANG_INCLUDE_DIR_C)/*.h

clean_imports: generate_fdump_bindings
	sed -e 's/pragma Import (CPP, \(.*\), ".*");/pragma Import (C, \1, "\1");/g' -i $(TMP_GEN_DIR)/clang_c_*_h.ads
	sed -e 's/\(with Interfaces.C; use Interfaces.C;\)/pragma Warnings (Off); \1 pragma Warnings (On);/g' -i $(TMP_GEN_DIR)/clang_c_*_h.ads
	sed -e 's/\(^.*[t|T]ime.*$\\)/--  \\1/g' -i $(TMP_GEN_DIR)/clang_c_index_h.ads
	rm $(TMP_GEN_DIR)/*time* $(TMP_GEN_DIR)/*types*

clean:
	rm $(TMP_GEN_DIR) -rf

distclean: clean
	rm $(CLANG_SRC_DIR) -rf
