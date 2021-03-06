#!/bin/sh -eu
#
# config.vm.provision "shell", path: "#{ENV['HOME']}/etc/vagrant/ptlocal.debian-family.sh", name: "pennocktech-local"

progname="$(basename -s .sh "$0")"
trace() { printf "%s: %s\n" "$progname" "$*" ; }

umask 022
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
pt_apt_get() { apt-get -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"; }

trace "timezone reset to UTC"
rm -f /etc/timezone
echo UTC > /etc/timezone
dpkg-reconfigure tzdata
unset TZ

trace "apt proxy, https, key, and PT repo"
pf=/etc/apt/apt.conf.d/70proxy
rm -vf $pf
touch $pf
# this uses a `not_at_home` command I have elsewhere:
[ -f /tmp/am_at_home ] && cat >> $pf <<'EOPROXY'
Acquire::http::Proxy "http://cheddar.lan:3142";
EOPROXY
cat >> $pf <<'EOPROXY'
Acquire::https::Proxy::apt.orchard.lan "DIRECT";
Acquire::https::Proxy::public-packages.pennock.tech "DIRECT";
EOPROXY
unset pf

# buster appears to not include a gnupg by default?
gpg --version >/dev/null 2>&1 || pt_apt_get install "${PT_GNUPG_VARIANT:-gnupg2}"

pt_apt_get install apt-transport-https

apt-key add - <<'EOKEY'
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBFef+wEBCACfAoCkz+gd2mtZ7IJLh0oGr61LP11o3yFGHF9zPOc+Usw4bY7v
MT8Wjfp1IIthxcWM5Vi0Zf+VuvZerf0e+6po+2xQAG/OnD74ZO1soiUD8pm3lczv
HQhWQ4FWAf6qSyngRxlhO2nbqpfnKbtEDtHa2EdfwIcuX5y0YLtWoDB6Dm0ANdP7
LXNgkU9f3tp1cty12tFxjBYy6ISrh8WuMV5IxKKZv9JFzayxyocnId7rxfrhEi0w
y0GY9b5x7+8rCE18TBIknSyg4aC901Yl9Qa5jpGO9lh8xnV2ljx4128mKwPObn4h
x6j+ZI98iHqgOZXvZU1ndG9Na+Rs8Jt4Hg9hABEBAAG0RlJlcG9zaXRvcnkgTWdt
dCAoZG8gbm90IHRydXN0IHRvIHNpZ24ga2V5cykgPHJlcG9tYW5AcGVubm9jay10
ZWNoLmNvbT6JAT4EEwECACgFAlef+wECGwMFCQ0oaIAGCwkIBwMCBhUIAgkKCwQW
AgMBAh4BAheAAAoJEIrI7jnwxokHjQcH/3QId5P/8wS18WKWyuOyJNeoRuYBIhip
S5o3R1JXpWq4t4GKYLaC6YAc3Fu3KrCks/nTsxC1I7YUSuHKTYluAgOxzr857Jmu
UvL2akxj3O/MQC0VTkSw05pPeOLhSERF+tUbmy9J6Jz6t1DnbPXpMzjr2ijUPAAZ
14c5odGEFXM1Oxls6GKzlEjUMFo5q3SYYVH/X4nG8CgMJtHsbXuYiXeG5J/0Qe0M
7aaatSCNbDLHj0qedl+ZECSd1UhWDZsr/Jy/qWs9KBwmxgtZ81VYYgJrS9G1JArv
rY6vBZ1OHbRntBMTeoPizq1puj/3N8+M67kBIFdjgdou+wOy+PQ/w/G5AQ0EV5/7
AQEIAMsGlLKZl8LrvByNeAKsnbiXz5MrFtb3dzZRc/2PqeLBwXQ2/Jc0tXdY2ez9
ixdAG43LXMIXrPILMfaMPCRrN83NpS0VHwYrm8WRhdJzq4SaCtgZ1quDAxFXdDFQ
98yjBCIA2E5p5E97NLXA6eguo6Zxy9QRmVmEGiCmMvi7Qm3jQ7ZW3dRue6HdVk4a
WjrT3RgyWa9AK7xmgSPIa7RtcBA5I/9Wu7jqVymhh639esmnFIt3BCdkaR44DhpE
2feln9Y9G4GpQfCwN5bRLkmE9aaQGcF0W/krxTAmdDngn/Dk6M5tGun+i3BbJUn+
hLUjt5OixjA9UpIf1SSakw/lFRsAEQEAAYkBJQQYAQIADwUCV5/7AQIbDAUJDSho
gAAKCRCKyO458MaJB4c5CACetpRHSI0LYtcewmcBEX2J1hY+GDS9fjD6OBW/6cpX
rgu93aci1+Mzw5MbSWcsZxl8cIJwT0iawuRmRHcScku8IYuG6UUALMig8UP1oPhe
L029nTixDw2VXNhEOgbQw4NRg2Mo03dEvwTNvUoTno6rEbGne0HzN7mz9siq9+s6
w65U70ePcyBx7r1CmwTIXJKyWMlNvTY3krgx69nWqFF8+u5uLPS4FCk2kWS2prI+
ubuNyV/Y2Mzfc9aqg/ZnY+FNRmJUCH5fONqXll9nOZUJqaFI7m3z0CJ3IQOakKoD
xwSe+uhHZPBdAe4XCcJL3o8YYSFqzmIkcwM4RJxIGBAH
=geWI
-----END PGP PUBLIC KEY BLOCK-----
EOKEY

distributor="$(lsb_release -si | tr A-Z a-z)"
codename="$(lsb_release -sc)"

if [ -z "${PT_DISABLE_PTREPOS:-}" ]; then
  cat > /etc/apt/sources.list.d/pennocktech.list <<EOSRC
deb https://public-packages.pennock.tech/pt/${distributor}/${codename}/ ${codename} main
EOSRC
fi

pt_apt_get update
