LIBNAME ?= libc
VARIANT ?= cm0
PREFIX ?= build
TARGETS ?= target_cm0 target_cm3 target_cm4fpu
TARGET_LIB = $(PREFIX)/lib/$(LIBNAME)
CFLAGS += $(EXTRA_CFLAGS)
CROSS_COMPILE ?= $(SNT_GCC)/arm-none-eabi-

CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)gcc
AR := $(CROSS_COMPILE)ar
RANLIB := $(CROSS_COMPILE)ranlib
SIZE := $(CROSS_COMPILE)size
OBJCOPY := $(CROSS_COMPILE)objcopy
RM := rm -rf
MKDIR := mkdir

# You can override the CFLAGS and C compiler externally,
CFLAGS += -Iinclude -Os -ggdb -std=gnu11
CFLAGS += -Wstrict-aliasing -Wall -Werror -Wno-comment -Wextra -Wno-ignored-qualifiers -Wstack-usage=256
CFLAGS += -fms-extensions -fmessage-length=0 -fstack-usage -fshort-enums -fshort-wchar
CFLAGS += -ffreestanding -nostartfiles -ffunction-sections -fdata-sections
CFLAGS += -fdiagnostics-color=always -fno-strict-aliasing -fno-builtin

# Just include all the source files in the build.
CSRC = $(wildcard src/*.c)
OBJS += $(addprefix ./$(PREFIX)/$(VARIANT)/,$(CSRC:.c=.o))
DEPS := $(OBJS:.o=.d)

# Some of the files uses "templates", i.e. common pieces
# of code included from multiple files.
CFLAGS += -Isrc/templates

all: targets

targets: $(TARGETS)
target_x64: #defunct for now
	make -C . $(TARGET_LIB)_x64.a VARIANT=x64 \ 
		EXTRA_CFLAGS="-rdynamic -fsanitize=address -fsanitize=undefined"

target_cm0:
	make -C . $(TARGET_LIB)_cm0.a VARIANT=cm0 \
		EXTRA_CFLAGS="-mcpu=cortex-m0 -mthumb -mfloat-abi=soft"

target_cm3:
	make -C . $(TARGET_LIB)_cm3.a VARIANT=cm3 \
		EXTRA_CFLAGS="-mcpu=cortex-m3 -mthumb -mfloat-abi=soft"

target_cm4fpu:
	make -C . $(TARGET_LIB)_cm4fpu.a VARIANT=cm4fpu \
		EXTRA_CFLAGS="-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16"

clean:
	$(RM) build
	$(RM) $(OBJS) $(TESTS_OBJS) libc.a

# Tool invocations
#$(PREFIX)/lib/$(TARGET_LIB)%.a: $(OBJS) deps
#$(PREFIX)/lib/%.a: $(OBJS) deps
$(TARGET_LIB)%.a: $(OBJS)
	@echo '[MKDIR] $(dir $@)'
	$(V)$(MKDIR) -p $(dir $@)
	@echo '[AR] $@'
	$(V)$(AR) cr $@ $(OBJS)
	@echo '[RANLIB] $@'
	$(V)$(RANLIB) $@
	@echo '[SIZE] $@'
	@echo "-------------------------------------------------------"
	$(V)$(SIZE) --format=berkeley -t "$@"
	@echo "-------------------------------------------------------"
	@echo "$(BUILD_TYPE) build complete on" `date`
	@echo "-------------------------------------------------------"

# [C] Generic build target
$(PREFIX)/$(VARIANT)/%.o: %.c $(PREFIX)/$(VARIANT)/%.d
	@echo '[C] $<'
	@mkdir -p $(dir $@)
	$(V)$(CC) $(CFLAGS) -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"

# [D] For dependencies
$(PREFIX)/$(VARIANT)/%.d: ;

.PRECIOUS: $(PREFIX)/$(VARIANT)/%.d

-include $(DEPS)
