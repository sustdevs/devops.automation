#! /bin/sh

# export I_PW=... ; export I_REPO_DIR=... ;
# `wget https://raw.githubusercontent.com/CICD-tools/devops.automation/master/nix/init.sh -O - | sh`

# set -eu  ## 'e' == exit/fail script on any command failure (note: causes `return` to function like `exit`); 'u' == use of unset variables causes exit/fail
# * ref: [Unexpected function of `-e`](http://mywiki.wooledge.org/BashFAQ/105)[`@`](http://archive.is/vRKCQ)
# * use `shellcheck` instead of `set -u` to catch variable misspellings

VERBOSE=${VERBOSE:-2}    # null, 0, 1, 2, ... == increasing logging verbosity

#

# host=4532CM.houseofivy.net
# port=42202
# user=toor

#
#: NOTE: QNAP version for limitations of busybox (`basename`, `dirname`, `readlink` unable to parse `--`; `readlink` throws errors on non-link arguments)
# shellcheck disable=SC2034
{
__ME_path="$0"
__ME_zero="$(echo "$0" | sed 's/^-/.\/-/')"
__ME=$(basename "$__ME_zero")
__ME_dir=$(dirname "$__ME_zero")
__ME_dir_abs=$(unset CDPATH; cd -- "$__ME_dir" && pwd -L)
__ME_dir_abs_physical=$(unset CDPATH; cd -- "$__ME_dir" && pwd -P)
__ME_path_abs="$__ME_dir_abs/$__ME"
__ME_realcwd_abs=$(pwd -P)
__ME_realpath_abs="$__ME_dir_abs_physical/$__ME" && [ -L "$__ME_realpath_abs" ] && __ME_realpath_abs=$(readlink "$__ME_realpath_abs")
__ME_realdir_abs=$(dirname "$__ME_realpath_abs")
}
#

am_root=""; if [ $(id -u) = 0 ]; then am_root=1; fi

PRINTF=$(which printf || echo "\"$(which busybox)\" printf")

truthy() { val="$(echo "$*" | tr '[:upper:]' '[:lower:]')" ; case $val in ""|"0"|"f"|"false"|"n"|"never"|"no"|"off") val="" ;; *) val=1 ;; esac ; echo "${val}" ; }

ANSI_COLOR=${ANSI_COLOR=auto} ; ANSI_COLOR="$(echo "${ANSI_COLOR}" | tr '[:upper:]' '[:lower:]')"
# echo "ANSI_COLOR = ${ANSI_COLOR}"
STDOUT_IS_TTY="" ; test -t 1 && STDOUT_IS_TTY=1
# echo "STDOUT_IS_TTY = ${STDOUT_IS_TTY}"
[ "${ANSI_COLOR}" = "auto" ] && ANSI_COLOR="${STDOUT_IS_TTY}"
# echo "ANSI_COLOR = ${ANSI_COLOR}"
ANSI_COLOR="$(truthy "${ANSI_COLOR}")"
echo "ANSI_COLOR = ${ANSI_COLOR}"
# exit 0

# color
ColorFullReset() { $PRINTF "%s" "${1}" ; [ "${ANSI_COLOR}" ] && $PRINTF "%s" '\033[m' ; }
ColorReset() { $PRINTF "%s" "${1}" ; [ "${ANSI_COLOR}" ] && $PRINTF "%s" '\033[0;39m' ; }
ColorBright() { [ "${ANSI_COLOR}" ] && $PRINTF "%s" '\033[1m' ; $PRINTF "%s" "$(ColorReset "${1}")" ; }
ColorRed()     { [ "${ANSI_COLOR}" ] && $PRINTF "%s" '\033[31m' ; $PRINTF "%s" "$(ColorReset "${1}")" ; }
ColorGreen()   { [ "${ANSI_COLOR}" ] && $PRINTF "%s" '\033[32m' ; $PRINTF "%s" "$(ColorReset "${1}")" ; }
ColorYellow()  { [ "${ANSI_COLOR}" ] && $PRINTF "%s" '\033[33m' ; $PRINTF "%s" "$(ColorReset "${1}")" ; }
ColorBlue()    { [ "${ANSI_COLOR}" ] && $PRINTF "%s" '\033[34m' ; $PRINTF "%s" "$(ColorReset "${1}")" ; }
ColorMagenta() { [ "${ANSI_COLOR}" ] && $PRINTF "%s" '\033[35m' ; $PRINTF "%s" "$(ColorReset "${1}")" ; }
ColorCyan()    { [ "${ANSI_COLOR}" ] && $PRINTF "%s" '\033[36m' ; $PRINTF "%s" "$(ColorReset "${1}")" ; }
ColorWhite()   { [ "${ANSI_COLOR}" ] && $PRINTF "%s" '\033[37m' ; $PRINTF "%s" "$(ColorReset "${1}")" ; }

# error functions
WARNmessage() { echo "$(ColorYellow "WARN:") ${*}" 1>&2 ; }
ERRmessage() { echo "$(ColorRed "ERR!:") ${*}" 1>&2 ; }
ExitWithError() { exit_val="${*}" ; exit_val=${exit_val:=1}; exit $exit_val ; }
ExitWithERRmessage() { ERRmessage "${*}" ; ExitWithError ; }

#

[ "${VERBOSE}" ] && echo "[ $(ColorCyan "${0}") $* ] (by $(whoami) (uid:$(id -u)))"

#

exit_val=0
test -z "${I_PW:=}" && { ERRmessage "missing password; use \`$(ColorCyan "export I_PW=...")\` to preset the information" ; exit_val=1 ; }
test -z "${I_REPO_DIR:=}" && { ERRmessage "missing directory specification; use \`$(ColorCyan "export I_REPO_DIR=...")\` to preset the information" ; exit_val=1 ; }
test "${exit_val}" -ne 0 && ExitWithError $exit_val

# * clone secrets, decrypt SSH keys and install them
## sudo apt update || ExitWithERRmessage "\`apt update\` failure"
which git >/dev/null || { sudo apt install git || ExitWithERRmessage "required \`git\` installation failure" ; }
which gpg >/dev/null || { sudo apt install gpg || ExitWithERRmessage "required \`gpg\` installation failure" ; }
## sudo apt install git gpg || ExitWithERRmessage "\`git\` and/or \`gpg\` installation failure"
git clone https://github.com/CICD-tools/devops.wass.git "${I_REPO_DIR}" || WARNmessage "\`git\` clone failure"
cd -- "${I_REPO_DIR}" || ExitWithERRmessage "unable to \`cd\` into ${I_REPO_DIR}"
__="ssh.tgz" ; test -f "${__}" && { WARNmessage "\"$(pwd -L)/${__}\" exists; removing it" ; rm "${__}" ; } ; unset __
gpg --batch --passphrase "${I_PW}" --output "ssh.tgz" --decrypt ssh.tgz.\[SACIv2\].gpg || ExitWithERRmessage "unable to decrypt data (is I_PW set correctly?)"
$PRINTF "Extracting SSH keys ... "
tar zxf "ssh.tgz" || ExitWithERRmessage "unable to extract SSH keys (\`tar zxf ...\` failed)"
chmod -R u+rw,og-rw,a-x "ssh"/*
export SSH_ID="$(pwd -L)/ssh/id_rsa"
echo "done"

# install unison (requires `sudo` to install for all users)
# ToDO: investigate local-user-only installation
me_ug="$(id -nu).$(id -ng)"
root_ug="$(sudo id -nu).$(sudo id -ng)"
sudo chown "$root_ug" "${SSH_ID}"
sudo bash -c "scp -i \"${SSH_ID}\" -P 42202 admin@4532CM.houseofivy.net:\"/share/Vault/#qnap/projects/unison/lib/scripts/\$\#install-unison.sh\" /dev/stdout | VERBOSE=2 sh"
sudo -i bash -c "~/.unison/scripts/##.sh -sshargs \\\"-i \\\"${SSH_ID}\\\"\\\""
sudo chown "$me_ug" "${SSH_ID}"
if [ ! $am_root ] ; then ~/".unison/scripts/##.sh" -sshargs \"-i \"${SSH_ID}\"\" ; fi

# # setup HOME directory symbolic links
# if [ ! $am_root ] ; then sudo -i bash -c '~/".sh/bin/sh-links-upinit.sh"' ; fi
# ~/".sh/bin/sh-links-upinit.sh"
