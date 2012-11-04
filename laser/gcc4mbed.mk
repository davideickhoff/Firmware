#Copyright (C) 2011 by Sagar G V
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.
#
# Updates: 
#    Arthur Wolf & Adam Green in 2011 - Updated to work with mbed.
###############################################################################
# USAGE:
# Variables that must be defined in including makefile.
#   PROJECT: Name to be given to the output binary for this project.
#   SRC: The root directory for the sources of your project.
#   GCC4MBED_DIR: The root directory for where the gcc4mbed sources are located
#                 in your project.  This should point to the parent directory
#                 of the build directory which contains this gcc4mbed.mk file.
#   LIBS_PREFIX: List of library/object files to prepend to mbed.ar capi.ar libs.
#   LIBS_SUFFIX: List of library/object files to append to mbed.ar capi.ar libs.
#   GCC4MBED_TYPE: Type of build to produce.  Allowed values are:
#                  Debug - Build for debugging.  Disables optimizations and
#                          links in debug MRI runtime.  Best debugging 
#                          experience.
#                  Release - Build for release with no debug support.
#                  Checked - Release build with debug support.  Due to
#                            optimizations, debug experience won't be as good
#                            as Debug but might be needed when bugs don't
#                            reproduce in Debug builds.
#                  default: Release
#   MRI_BREAK_ON_INIT: Should the program halt before calling into main(),
#                      allowing the developer time to set breakpoints in main()
#                      or in code run from within global constructors.
#                      default: 1 - break on init.
#   MRI_SEMIHOST_STDIO: Set to non-zero value to allow debug monitor to use
#                       semi-host calls to redirect stdin/stdout/stderr to the
#                       gdb console.
#                       default: 1 for Debug/Checked builds and 0 for Release.
#   MRI_UART: Select the UART to be used by the debugger.  See mri.h for
#             allowed values.
#             default: MRI_UART_MBED_USB - Use USB based UART on the mbed.
# Example makefile:
#       PROJECT=HelloWorld
#       SRC=.
#       GCC4MBED_DIR=../..
#       LIBS_PREFIX=../agutil/agutil.ar
#       LIBS_SUFFIX=
#
#       include ../../build/gcc4mbed.mk
#      
###############################################################################

# Check for undefined variables.
ifndef PROJECT
$(error makefile must set PROJECT variable.)
endif

ifndef GCC4MBED_DIR
$(error makefile must set GCC4MBED_DIR.)
endif


# Default variables.
SRC ?= .
GCC4MBED_TYPE ?= Release
MRI_BREAK_ON_INIT ?= 1
MRI_UART ?= MRI_UART_MBED_USB


# Configure MRI variables based on GCC4MBED_TYPE build type variable.
ifeq "$(GCC4MBED_TYPE)" "Release"
OPTIMIZATION ?= 2
MRI_ENABLE = 0
MRI_SEMIHOST_STDIO ?= 0
endif


ifeq "$(GCC4MBED_TYPE)" "Debug"
OPTIMIZATION = 0
MRI_ENABLE = 1
MRI_SEMIHOST_STDIO ?= 1
endif


ifeq "$(GCC4MBED_TYPE)" "Checked"
OPTIMIZATION ?= 2
MRI_ENABLE = 1
MRI_SEMIHOST_STDIO ?= 1
endif

MRI_INIT_PARAMETERS=$(MRI_UART)


# Output Object Directory
OUTDIR=LPC1768
OUTDIRLPC=LPC1769

# List of sources to be compiled/assembled
CSRCS = $(wildcard $(SRC)/*.c $(SRC)/*/*.c $(SRC)/*/*/*.c $(SRC)/*/*/*/*.c $(SRC)/*/*/*/*/*.c)
ASRCS =  $(wildcard $(SRC)/*.S $(SRC)/*/*.S $(SRC)/*/*/*.S $(SRC)/*/*/*/*.S $(SRC)/*/*/*/*/*.S)
ifneq "$(OS)" "Windows_NT"
ASRCS +=  $(wildcard $(SRC)/*.s $(SRC)/*/*.s $(SRC)/*/*/*.s $(SRC)/*/*/*/*.s $(SRC)/*/*/*/*/*.s)
endif
CPPSRCS = $(wildcard $(SRC)/*.cpp $(SRC)/*/*.cpp $(SRC)/*/*/*.cpp $(SRC)/*/*/*/*.cpp $(SRC)/*/*/*/*/*.cpp)

# List of the objects files to be compiled/assembled
OBJECTS = $(patsubst %.c,$(OUTDIR)/%.o,$(CSRCS)) $(patsubst %.s,$(OUTDIR)/%.o,$(patsubst %.S,$(OUTDIR)/%.o,$(ASRCS))) $(patsubst %.cpp,$(OUTDIR)/%.o,$(CPPSRCS))
OBJECTSLPC = $(patsubst %.c,$(OUTDIRLPC)/%.o,$(CSRCS)) $(patsubst %.s,$(OUTDIRLPC)/%.o,$(patsubst %.S,$(OUTDIRLPC)/%.o,$(ASRCS))) $(patsubst %.cpp,$(OUTDIRLPC)/%.o,$(CPPSRCS))

# Add in the GCC4MBED stubs which allow hooking in the MRI debug monitor.
OBJECTS += $(OUTDIR)/gcc4mbed.o
OBJECTSLPC += $(OUTDIRLPC)/gcc4mbed.o

# List of the header dependency files, one per object file.
DEPFILES = $(patsubst %.o,%.d,$(OBJECTS))
DEPFILESLPC = $(patsubst %.o,%.d,$(OBJECTSLPC))

# Linker script to be used.  Indicates what code should be placed where in memory.
LSCRIPT=$(GCC4MBED_DIR)/build/mbed.ld
LSCRIPTLPC=lpcexpresso.ld

# Location of external library and header dependencies.
EXTERNAL_DIR = $(GCC4MBED_DIR)/external

# Include path which points to external library headers and to subdirectories of this project which contain headers.
SUBDIRS = $(wildcard $(SRC)/* $(SRC)/*/* $(SRC)/*/*/* $(SRC)/*/*/*/* $(SRC)/*/*/*/*/*)
PROJINCS = $(sort $(dir $(SUBDIRS)))
INCDIRS += $(PROJINCS) $(GCC4MBED_DIR)/mri $(EXTERNAL_DIR)/mbed $(EXTERNAL_DIR)/mbed/LPC1768

# DEFINEs to be used when building C/C++ code
DEFINES += -DTARGET_LPC1768
DEFINES += -DMRI_ENABLE=$(MRI_ENABLE) -DMRI_INIT_PARAMETERS='"$(MRI_INIT_PARAMETERS)"' 
DEFINES += -DMRI_BREAK_ON_INIT=$(MRI_BREAK_ON_INIT) -DMRI_SEMIHOST_STDIO=$(MRI_SEMIHOST_STDIO)

# Libraries to be linked into final binary
MBED_LIBS = $(EXTERNAL_DIR)/mbed/LPC1768/GCC_ARM/libmbed.a $(EXTERNAL_DIR)/mbed/LPC1768/GCC_ARM/libcapi.a
SYS_LIBS = -lstdc++ -lsupc++ -lm -lgcc -lc -lgcc -lc -lnosys
LIBS = $(LIBS_PREFIX) 

ifeq "$(MRI_ENABLE)" "1"
LIBS += $(GCC4MBED_DIR)/mri/mri.ar
endif

LIBS += $(EXTERNAL_DIR)/mbed/LPC1768/GCC_ARM/startup_LPC17xx.o
LIBS += $(EXTERNAL_DIR)/mbed/LPC1768/GCC_ARM/cmsis_nvic.o
LIBS += $(EXTERNAL_DIR)/mbed/LPC1768/GCC_ARM/core_cm3.o
LIBS += $(EXTERNAL_DIR)/mbed/LPC1768/GCC_ARM/system_LPC17xx.o
LIBS += $(MBED_LIBS)
LIBS += $(SYS_LIBS)
LIBS += $(LIBS_SUFFIX)

# Compiler flags used to enable creation of header dependencies.
DEPFLAGS = -MMD -MP

# Compiler Options
GPFLAGS = -O$(OPTIMIZATION) -g -mcpu=cortex-m3 -mthumb -mthumb-interwork 
GPFLAGS += -ffunction-sections -fdata-sections  -fno-exceptions -fno-delete-null-pointer-checks
GPFLAGS += $(patsubst %,-I%,$(INCDIRS))
GPFLAGS += $(DEFINES)
GPFLAGS += $(DEPFLAGS)
GPFLAGS += -Wall -Wextra -Wno-unused-parameter -Wcast-align -Wpointer-arith -Wredundant-decls -Wcast-qual -Wcast-align

GCFLAGS = $(GPFLAGS)

AS_GCFLAGS = -g -mcpu=cortex-m3 -mthumb -x assembler-with-cpp
AS_GCFLAGS += $(patsubst %,-I%,$(INCDIRS))
AS_FLAGS = -g -mcpu=cortex-m3 -mthumb


# Setup wraps for newlib read/writes to redirect to MRI debugger. 
ifeq "$(MRI_ENABLE)" "1"
MRI_WRAPS=,--wrap=_read,--wrap=_write,--wrap=semihost_connected
else
MRI_WRAPS=
endif

# Linker Options.
LDFLAGS = -mcpu=cortex-m3 -mthumb -O$(OPTIMIZATION) -specs=$(GCC4MBED_DIR)/build/startfile.spec -Wl,-Map=$(OUTDIR)/$(PROJECT).map,--cref,--gc-sections,--wrap=_isatty$(MRI_WRAPS) -T$(LSCRIPT)  -L $(EXTERNAL_DIR)/gcc/LPC1768
LDFLAGSLPC = -mcpu=cortex-m3 -mthumb -O$(OPTIMIZATION) -specs=$(GCC4MBED_DIR)/build/startfile.spec -Wl,-Map=$(OUTDIRLPC)/$(PROJECT).map,--cref,--gc-sections,--wrap=_isatty$(MRI_WRAPS) -T$(LSCRIPTLPC)  -L $(EXTERNAL_DIR)/gcc/LPC1768

#  Compiler/Assembler/Linker Paths
GCC = arm-none-eabi-gcc
GPP = arm-none-eabi-g++
AS = arm-none-eabi-as
LD = arm-none-eabi-g++
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE = arm-none-eabi-size

# Some tools are different on Windows in comparison to Unix.
ifeq "$(OS)" "Windows_NT"
REMOVE = del
SHELL=cmd.exe
REMOVE_DIR = rd /s /q
MKDIR = mkdir
QUIET=>nul 2>nul & exit 0
else
REMOVE = rm
REMOVE_DIR = rm -r -f
MKDIR = mkdir -p
QUIET=> /dev/null 2>&1 ; exit 0
endif

# Create macro which will convert / to \ on Windows.
ifeq "$(OS)" "Windows_NT"
define convert-slash
$(subst /,\,$1)
endef
else
define convert-slash
$1
endef
endif

#########################################################################
.PHONY: all clean deploy

all:: $(PROJECT).hex $(PROJECT)-lpc.hex $(PROJECT).bin $(PROJECT)-lpc.bin $(OUTDIR)/$(PROJECT).disasm $(OUTDIRLPC)/$(PROJECT).disasm

$(PROJECT).bin: $(PROJECT).elf
	$(OBJCOPY) -O binary $(PROJECT).elf $(PROJECT).bin

$(PROJECT)-lpc.bin: $(PROJECT)-lpc.elf
	$(OBJCOPY) -O binary $(PROJECT)-lpc.elf $(PROJECT)-lpc.bin

$(PROJECT).hex: $(PROJECT).elf
	$(OBJCOPY) -R .stack -O ihex $(PROJECT).elf $(PROJECT).hex
	
$(PROJECT)-lpc.hex: $(PROJECT)-lpc.elf
	$(OBJCOPY) -R .stack -O ihex $(PROJECT)-lpc.elf $(PROJECT)-lpc.hex

$(OUTDIR)/$(PROJECT).disasm: $(PROJECT).elf
	$(OBJDUMP) -d -f -M reg-names-std $(PROJECT).elf >$(OUTDIR)/$(PROJECT).disasm

$(OUTDIRLPC)/$(PROJECT).disasm: $(PROJECT)-lpc.elf
	$(OBJDUMP) -d -f -M reg-names-std $(PROJECT)-lpc.elf >$(OUTDIRLPC)/$(PROJECT).disasm
		
$(PROJECT).elf: $(LSCRIPT) $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) $(LIBS) -o $(PROJECT).elf
	$(SIZE) $(PROJECT).elf

$(PROJECT)-lpc.elf: $(LSCRIPTLPC) $(OBJECTSLPC)
	$(LD) $(LDFLAGSLPC) $(OBJECTSLPC) $(LIBS) -o $(PROJECT)-lpc.elf
	$(SIZE) $(PROJECT)-lpc.elf

clean:
	$(REMOVE) -f $(call convert-slash,$(OBJECTS)) $(QUIET)
	$(REMOVE) -f $(call convert-slash,$(DEPFILES)) $(QUIET)
	$(REMOVE_DIR) $(OUTDIR) $(QUIET)
	$(REMOVE_DIR) $(OUTDIRLPC) $(QUIET)
	$(REMOVE) -f $(call convert-slash,$(OUTDIR)/$(PROJECT).map) $(QUIET)
	$(REMOVE) -f $(call convert-slash,$(OUTDIRLPC)/$(PROJECT).map) $(QUIET)
	$(REMOVE) -f $(call convert-slash,$(OUTDIR)/$(PROJECT).disasm) $(QUIET)
	$(REMOVE) -f $(call convert-slash,$(OUTDIRLPC)/$(PROJECT).disasm) $(QUIET)
	$(REMOVE) -f $(PROJECT)-lpc.bin $(QUIET)
	$(REMOVE) -f $(PROJECT).bin $(QUIET)
	$(REMOVE) -f $(PROJECT).hex $(QUIET)
	$(REMOVE) -f $(PROJECT)-lpc.hex $(QUIET)
	$(REMOVE) -f $(PROJECT).elf $(QUIET)
	$(REMOVE) -f $(PROJECT)-lpc.elf $(QUIET)

-include $(DEPFILES)

ifdef LPC_DEPLOY
DEPLOY_COMMAND = $(subst PROJECT,$(PROJECT),$(LPC_DEPLOY))
deploy:
	$(DEPLOY_COMMAND)
endif

#########################################################################
#  Default rules to compile .c and .cpp file to .o
#  and assemble .s files to .o

$(OUTDIR)/gcc4mbed.o : $(GCC4MBED_DIR)/src/gcc4mbed.c
	$(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(GPP) $(GPFLAGS) -c $< -o $@

$(OUTDIR)/%.o : %.cpp
	$(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(GPP) $(GPFLAGS) -c $< -o $@

$(OUTDIR)/%.o : %.c
	$(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(GCC) $(GCFLAGS) -c $< -o $@

$(OUTDIR)/%.o : %.S
	$(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(GCC) $(AS_GCFLAGS) -c $< -o $@

$(OUTDIR)/%.o : %.s
	$(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(AS) $(AS_FLAGS) -o $@ $<

$(OUTDIRLPC)/gcc4mbed.o : $(GCC4MBED_DIR)/src/gcc4mbed.c
	$(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(GPP) $(GPFLAGS) -DXPRESSO -c $< -o $@

$(OUTDIRLPC)/%.o : %.cpp
	$(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(GPP) $(GPFLAGS) -DXPRESSO -c $< -o $@

$(OUTDIRLPC)/%.o : %.c
	$(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(GCC) $(GCFLAGS) -DXPRESSO -c $< -o $@

$(OUTDIRLPC)/%.o : %.S
	$(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(GCC) $(AS_GCFLAGS) -DXPRESSO -c $< -o $@

$(OUTDIRLPC)/%.o : %.s
	$(MKDIR) $(call convert-slash,$(dir $@)) $(QUIET)
	$(AS) $(AS_FLAGS) -DXPRESSO -o $@ $<

#########################################################################
