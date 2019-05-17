#! /bin/sh

set -eu  ## 'e' == exit/fail script on any command failure; 'u' == use of unset variables causes exit/fail

#

VERBOSE=${VERBOSE:-2}    # null, 0, 1, 2, ... == increasing logging verbosity

#

host=4532CM.houseofivy.net
port=42202
user=toor

#
#: NOTE: QNAP version for limitations of busybox (`basename`, `dirname`, `readlink` unable to parse `--`; `readlink` throws errors on non-link arguments)
__ME=$(basename "$0")
__ME_path="$0"
__ME_dir=$(dirname "$0")
__ME_dir_abs=$(unset CDPATH; cd -- "$__ME_dir" && pwd -L)
__ME_dir_abs_physical=$(unset CDPATH; cd -- "$__ME_dir" && pwd -P)
__ME_path_abs="$__ME_dir_abs/$__ME"
__ME_realcwd_abs=$(pwd -P)
__ME_realpath_abs="$__ME_dir_abs_physical/$__ME" && [ -L "$__ME_realpath_abs" ] && __ME_realpath_abs=$(readlink "$__ME_realpath_abs")
__ME_realdir_abs=$(dirname "$__ME_realpath_abs")
#

[ $VERBOSE ] && echo "[ $0 $* ] (by $(whoami) (uid:$(id -u)))"

#

exit_val=0
test -z "${I_PW:=}" && ( echo "ERR!: missing password; use \`export I_PW=...\` to preset the information" 1>&2 ; exit_val=1 ; )
test -z "${I_REPO_DIR:=}" && ( echo "ERR!: missing directory specification; use \`export I_REPO_DIR=...\` to preset the information" 1>&2 ; exit_val=1 ; )
test $exit_val -ne 0  && ( return 1 >/dev/null || exit 1 ) ;

#* clone secrets and decrypt them
sudo apt update
sudo apt install git gpg
git clone https://github.com/CICD-tools/devops.wass.git REPO_DIR
cd REPO_DIR
gpg --batch --passphrase "$GPW" --output ssh.tgz --decrypt ssh.tgz.\[SACIv2\].gpg
tar zxf ssh.tgz
cp ssh/* ~/.ssh
chmod u+rw,og-rw,a-x ~/.ssh/id_*
