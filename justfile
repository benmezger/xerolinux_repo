# By Ben Mezger
# https://github.com/benmezger
# https://seds.nl

set shell := ["/bin/bash", "-c", "-eu", "-o", "pipefail"]
PACKAGE_FILE := "PACKAGES"
makepkg_flags := ""
install := "true"

arch := "x86_64"
pkgsdir := "pkgs"

# Build order:
# 1. clone <package>
# 2. build <package>
# 3. pkgcheck <package>
# 4. copy <package>
# 5. manually run ./build-db.sh in $pkgsdir

all:
        @echo "Using {{PACKAGE_FILE}} file"
        mkdir -pv {{pkgsdir}}

        for pkg in `cat {{PACKAGE_FILE}}`; do \
            just pkgsdir={{pkgsdir}} clone $pkg; \
            just makepkg_flags={{makepkg_flags}} pkgsdir={{pkgsdir}} build $pkg; \
            just pkgsdir={{pkgsdir}} pkgcheck $pkg; \
            just pkgsdir={{pkgsdir}} release $pkg; \
        done

clone target:
        @echo "Closing {{target}}"
        git clone --depth 1 https://aur.archlinux.org/{{target}}.git {{pkgsdir}}/{{target}}

build target:
        @echo "Building {{target}}"
        cd {{pkgsdir}}/{{target}} && makepkg -s --noconfirm {{makepkg_flags}}
        if "{{install}}" = "true"; then \
            cd {{pkgsdir}}/{{target}} && sudo pacman -U --noconfirm *.pkg.tar.zst; \
        fi

clean:
        rm -rfv {{pkgsdir}}

pkgcheck target:
        @echo "Checking if there is no new package update"
        if ! ls {{pkgsdir}}/{{target}} | grep -q pkg.tar.zst ; then \
              echo "No generated PKG found for {{target}}"; \
              exit 1; \
        fi

release target:
        @echo "Releasing {{target}}"
        cd {{pkgsdir}}/{{target}} && cp -rf *.pkg.tar.zst ../../x86_64
        bash ./update.sh
