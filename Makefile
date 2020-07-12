NAME=hocho
VERS=0.0.1

PACKER_VERSION=1.5.2

USER=$(shell whoami)
FILE_NAME=$(NAME)-raspbian-lite-$(VERS)

WIFI_NAME:=$(shell cat password | jq .name -r)
WIFI_PASS:=$(shell cat password | jq .password -r)


.PHONY: all install clean apt-deps

pass: password
	@echo $(WIFI_NAME)
	@echo $(WIFI_PASS)

all: clean install image


install: apt-deps /usr/bin/packer /usr/bin/packer-builder-arm-image


dist: gz zip image


apt-deps:
	sudo -H apt install -y kpartx qemu-user-static


/usr/bin/packer:
	curl https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip -o /tmp/packer.zip
	unzip /tmp/packer.zip -d /tmp
	sudo mv /tmp/packer /usr/bin/packer


/usr/bin/packer-builder-arm-image:
	rm -fr /tmp/packer-builder-arm-image
	git clone https://github.com/solo-io/packer-builder-arm-image /tmp/packer-builder-arm-image
	cd /tmp/packer-builder-arm-image && go get -d ./... && go build
	sudo cp /tmp/packer-builder-arm-image/packer-builder-arm-image /usr/bin


image:
	cd builder && sudo /usr/bin/packer build \
		-var wifi_name="$(WIFI_NAME)" \
		-var wifi_pass="$(WIFI_PASS)" \
		hocho.json
	mkdir -p dist/$(FILE_NAME)
	sudo mv builder/output-$(NAME)/image dist/$(FILE_NAME)/$(FILE_NAME).img
	sudo chown -R $(USER): dist
	sha256sum dist/$(FILE_NAME)/$(FILE_NAME).img > dist/$(FILE_NAME)/$(FILE_NAME).sha256


gz: image
	cd dist && tar czf $(FILE_NAME).tar.gz $(FILE_NAME)

zip: image
	cd dist && zip $(FILE_NAME).zip $(FILE_NAME)/$(FILE_NAME).sha256 $(FILE_NAME)/$(FILE_NAME).img

dd-cmd:
	echo "dd bs=4M if=dist/thing-raspbian-lite-0.0.1/thing-raspbian-lite-0.0.1.img of=<PUT_DEVICE_HERE> status=progress conv=fsync"


clean:
	sudo rm -fr \
		/tmp/packer-builder-arm-image \
		dist \
		builder/output-$(NAME)
