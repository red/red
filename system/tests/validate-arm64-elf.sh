#!/bin/sh
set -eu

exe=${1:?usage: validate-arm64-elf.sh executable shared-object}
shared=${2:?usage: validate-arm64-elf.sh executable shared-object}

fail() {
	echo "ARM64 ELF validation failed: $1" >&2
	exit 1
}

require_match() {
	value=$1
	pattern=$2
	message=$3
	if ! printf '%s\n' "$value" | grep -Eq "$pattern"; then
		fail "$message"
	fi
}

reject_match() {
	value=$1
	pattern=$2
	message=$3
	if printf '%s\n' "$value" | grep -Eq "$pattern"; then
		fail "$message"
	fi
}

validate_relocations() {
	file=$1
	for type in $(readelf -rW "$file" | awk '$3 ~ /^R_AARCH64_/ {print $3}' | sort -u); do
		case "$type" in
			R_AARCH64_RELATIVE|R_AARCH64_GLOB_DAT|R_AARCH64_JUMP_SLOT) ;;
			*) fail "$file contains unexpected dynamic relocation $type" ;;
		esac
	done
}

exe_header=$(readelf -hW "$exe")
require_match "$exe_header" 'Class:[[:space:]]+ELF64' "$exe is not ELF64"
require_match "$exe_header" 'Data:.*little endian' "$exe is not little-endian"
require_match "$exe_header" 'Type:[[:space:]]+DYN .*Position-Independent Executable' "$exe is not ET_DYN/PIE"
require_match "$exe_header" 'Machine:[[:space:]]+AArch64' "$exe is not AArch64"
reject_match "$exe_header" 'Entry point address:[[:space:]]+0x0$' "$exe has no entry point"

exe_segments=$(readelf -lW "$exe")
require_match "$exe_segments" 'Requesting program interpreter: /lib/ld-linux-aarch64.so.1' "$exe has the wrong interpreter"
require_match "$exe_segments" '^[[:space:]]*GNU_STACK[[:space:]].*[[:space:]]RW[[:space:]]+' "$exe has an executable or missing GNU_STACK"
require_match "$exe_segments" '^[[:space:]]*GNU_RELRO[[:space:]]' "$exe has no GNU_RELRO segment"
reject_match "$exe_segments" '^[[:space:]]*LOAD.*[[:space:]]RWE[[:space:]]' "$exe has an RWE load segment"

exe_dynamic=$(readelf -dW "$exe")
require_match "$exe_dynamic" 'FLAGS_1.*PIE' "$exe has no DF_1_PIE flag"
reject_match "$exe_dynamic" 'TEXTREL' "$exe contains text relocations"
validate_relocations "$exe"

shared_header=$(readelf -hW "$shared")
require_match "$shared_header" 'Class:[[:space:]]+ELF64' "$shared is not ELF64"
require_match "$shared_header" 'Data:.*little endian' "$shared is not little-endian"
require_match "$shared_header" 'Type:[[:space:]]+DYN .*Shared object' "$shared is not an ET_DYN shared object"
require_match "$shared_header" 'Machine:[[:space:]]+AArch64' "$shared is not AArch64"
require_match "$shared_header" 'Entry point address:[[:space:]]+0x0$' "$shared has a nonzero entry point"

shared_segments=$(readelf -lW "$shared")
reject_match "$shared_segments" '^[[:space:]]*INTERP[[:space:]]' "$shared contains a PT_INTERP segment"
require_match "$shared_segments" '^[[:space:]]*GNU_STACK[[:space:]].*[[:space:]]RW[[:space:]]+' "$shared has an executable or missing GNU_STACK"
require_match "$shared_segments" '^[[:space:]]*GNU_RELRO[[:space:]]' "$shared has no GNU_RELRO segment"
reject_match "$shared_segments" '^[[:space:]]*LOAD.*[[:space:]]RWE[[:space:]]' "$shared has an RWE load segment"

shared_dynamic=$(readelf -dW "$shared")
require_match "$shared_dynamic" 'SONAME.*\[libtest-dll1\.so\]' "$shared has the wrong SONAME"
reject_match "$shared_dynamic" 'FLAGS_1.*PIE' "$shared is incorrectly tagged as PIE"
reject_match "$shared_dynamic" 'TEXTREL' "$shared contains text relocations"
validate_relocations "$shared"

shared_symbols=$(readelf --dyn-syms -W "$shared")
require_match "$shared_symbols" 'GLOBAL[[:space:]]+DEFAULT[[:space:]]+[0-9]+[[:space:]]+add-one$' "$shared does not export add-one"

echo "ARM64 ELF validation passed: $exe and $shared"
