# By Ben Mezger
# https://github.com/benmezger
# https://seds.nl

set shell := ["/bin/bash", "-c", "-eu", "-o", "pipefail"]
PACKAGE_FILE := "PACKAGES"
makepkg_flags := ""

arch := "x86_64"
pkgsdir := "pacman-local"

# Build order:
# 1. clone <package>
# 2. build <package>
# 3. pkgcheck <package>
# 4. copy <package>
# 5. manually run ./build-db.sh in $pkgsdir

all:
        @echo "Using {{PACKAGE_FILE}} file"
        mkdir -pv $pkgsdir

        for pkg in `cat {{PACKAGE_FILE}}`; do \
            just clone $pkg
            just makepkg_flags={{makepkg_flags}} build $pkg; \
            just pkgcheck $pkg; \
            just pkgsdir={{pkgsdir}} copy $pkg; \
        done


clone: target:
        @echo "Closing {{target}}"
        git clone https://aur.archlinux.org/{{target}}.git $pkgsdir

build target:
        @echo "Building {{target}}"
        cd {{pkgsdir}}/{{target}} && makepkg -s --noconfirm {{makepkg_flags}}

clean:
        find . -name *.pkg.tar.zst -exec rm -rfv {} \;

pkgcheck target:
        @echo "Checking if there is no new package update"
        if ! ls {{pkgsdir}}/{{target}} | grep -q pkg.tar.zst ; then \
              echo "No generated PKG found for {{target}}"; \
              exit 1; \
        fi

check-updates:
        @echo "Using {{PACKAGE_FILE}} file"
        for pkg in `cat {{PACKAGE_FILE}}`; do \
            just makepkg_flags="--nobuild" build $pkg; \
        done

        git diff
