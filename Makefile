# Compatible with GNU make and BSD make.

include config.mk

install:
	@echo Installing to to ${PREFIX}/bin ...
	@mkdir -p ${PREFIX}/bin
	@cp -f bin/hubsh ${PREFIX}/bin
	@cp -f bin/gogsh ${PREFIX}/bin
	@chmod 755 ${PREFIX}/bin/hubsh
	@chmod 755 ${PREFIX}/bin/gogsh

uninstall:
	@echo Uninstalling from ${PREFIX}/bin ...
	@rm -f ${PREFIX}/bin/hubsh
	@rm -f ${PREFIX}/bin/gogsh
