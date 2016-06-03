.PHONY: all eur usa

################################################################################
all: new_eur old_eur new_usa old_usa
new_eur: build/new_eur/exploit/DCIM/100NIN03/HNI_0001.JPG build/new_eur/exploit/freaky.bin
old_eur: build/old_eur/exploit/DCIM/100NIN03/HNI_0001.JPG build/old_eur/exploit/freaky.bin
new_usa: build/new_usa/exploit/DCIM/100NIN03/HNI_0001.JPG build/new_usa/exploit/freaky.bin
old_usa: build/old_usa/exploit/DCIM/100NIN03/HNI_0001.JPG build/old_usa/exploit/freaky.bin
clean:
	rm -rf build/

### STAGE 0 (QR CODE + INITIAL ROP) ############################################
build/new_eur/stage0.elf: DEFINES := -DEUR -DNEW3DS
build/old_eur/stage0.elf: DEFINES := -DEUR
build/new_usa/stage0.elf: DEFINES := -DUSA -DNEW3DS
build/old_usa/stage0.elf: DEFINES := -DUSA

build/%/stage0.elf: src/stage0.s
	mkdir -p $(dir $@)
	arm-none-eabi-gcc -x assembler-with-cpp -nostartfiles -nostdlib -o $@ $< $(DEFINES)

build/%/stage0.bin: build/%/stage0.elf
	arm-none-eabi-objcopy -O binary $< $@

build/%/stage0_qr.bin: build/%/stage0.bin
	./scripts/add_qr_header.py $< $@

build/%/stage0_qr.png: build/%/stage0_qr.bin
	qrencode -8 -o $@ < $<

build/%/stage0_qr.jpg: build/%/stage0_qr.png
	convert $< -resize 60% $@

### STAGE 1 (MORE ROP) #########################################################
build/new_eur/stage1.elf: DEFINES := -DEUR -DNEW3DS
build/old_eur/stage1.elf: DEFINES := -DEUR
build/new_usa/stage1.elf: DEFINES := -DUSA -DNEW3DS
build/old_usa/stage1.elf: DEFINES := -DUSA

build/%/stage1.elf: src/stage1.s
	mkdir -p $(dir $@)
	arm-none-eabi-gcc -x assembler-with-cpp -nostartfiles -nostdlib -o $@ $< $(DEFINES)

build/%/stage1.bin: build/%/stage1.elf
	arm-none-eabi-objcopy -O binary $< $@

### STAGE 2 (CODE) #############################################################
build/new_eur/stage2.elf: DEFINES := -DEUR -DNEW3DS
build/old_eur/stage2.elf: DEFINES := -DEUR
build/new_usa/stage2.elf: DEFINES := -DUSA -DNEW3DS
build/old_usa/stage2.elf: DEFINES := -DUSA

build/%/stage2.elf: src/stage2.s
	mkdir -p $(dir $@)
	arm-none-eabi-gcc -x assembler-with-cpp -nostartfiles -nostdlib -o $@ $< $(DEFINES)

build/%/stage2.bin: build/%/stage2.elf
	arm-none-eabi-objcopy -O binary $< $@

### EXPLOIT OUTPUTS ############################################################
build/%/exploit/DCIM/100NIN03/HNI_0001.JPG: build/%/stage0_qr.jpg
	mkdir -p $(dir $@)
	composite $< -geometry +220+40 ./data/template.jpg $@

build/%/exploit/freaky.bin: build/%/stage1.bin build/%/stage2.bin
	cat $^ > $@
	xxd $@
