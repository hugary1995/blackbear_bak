NEML2_DIR            ?= $(BLACKBEAR_DIR)/contrib/neml2

ifneq ($(wildcard $(NEML2_DIR)/CMakeLists.txt),)

neml2_INCLUDE        := $(NEML2_DIR)/include
neml2_SRC            := $(shell find $(NEML2_DIR)/src -name "*.cxx")
neml2_OBJ            := $(patsubst %.cxx,%.$(obj-suffix),$(neml2_SRC))
neml2_LIB            := $(NEML2_DIR)/libneml2-$(METHOD).la

$(APPLICATION_DIR)/lib/libblackbear-$(METHOD).la: $(neml2_LIB)

$(neml2_LIB): $(neml2_OBJ)
	@echo "Linking Library "$@"..."
	@$(libmesh_LIBTOOL) --tag=CC $(LIBTOOLFLAGS) --mode=link --quiet \
	  $(libmesh_CC) $(libmesh_CFLAGS) -o $@ $(neml2_OBJ) $(libmesh_LDFLAGS) $(EXTERNAL_FLAGS) -rpath $(NEML2_DIR)
	@$(libmesh_LIBTOOL) --mode=install --quiet install -c $(neml2_LIB) $(NEML2_DIR)

$(NEML2_DIR)/src/%.$(obj-suffix) : $(NEML2_DIR)/src/%.cxx
	@echo "Compiling C++ (in "$(METHOD)" mode) "$<"..."
	@$(libmesh_LIBTOOL) --tag=CXX $(LIBTOOLFLAGS) --mode=compile --quiet \
	  $(libmesh_CXX) $(libmesh_CPPFLAGS) $(ADDITIONAL_CPPFLAGS) $(libmesh_CXXFLAGS) $(app_INCLUDES) $(libmesh_INCLUDE) -w -DHAVE_CONFIG_H -MMD -MP -MF $@.d -MT $@ -c $< -o $@

ADDITIONAL_INCLUDES  += -iquote$(neml2_INCLUDE)
ADDITIONAL_LIBS      += -L$(NEML2_DIR) -lneml2-$(METHOD)
ADDITIONAL_CPPFLAGS  += -DNEML2_ENABLED
NONUNITY_DIRS        += $(shell find src/nonunity -type d -not -path '*/.libs*' 2> /dev/null)
NONUNITY_DIRS        += $(shell find test/src/nonunity -type d -not -path '*/.libs*' 2> /dev/null)
app_non_unity_dirs   += $(foreach i, $(NONUNITY_DIRS), %$(i))

else
$(info WARNING: Not building with neml2 because contrib/neml2 submodule is not present and NEML2_DIR was not set to a valid neml2 checkout)
$(info See https://reverendbedford.github.io/neml2/install.html)
endif
