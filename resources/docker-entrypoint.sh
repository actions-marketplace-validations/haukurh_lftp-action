#!/usr/bin/env sh

# Throw error if FTP_HOST is not provided
if [ -z "${INPUT_FTP_HOST}" ]; then
	echo "Error: FTP_HOST not set!" 1>&2
	exit 1
fi

# Setting some defaults
FTP_USER="${INPUT_FTP_USER:-anonymous}"
FTP_PORT="${INPUT_FTP_PORT:-22}"
FTP_PROTOCOL="${INPUT_FTP_PROTOCOL:-sftp}"
FTP_FORCE_SSL="${INPUT_FTP_FORCE_SSL:-true}"
SSL_VERIFY_CERT="${INPUT_SSL_VERIFY_CERT:-true}"

if [ -n "${INPUT_FTP_PASS}" ]; then
	export LFTP_PASSWORD="${INPUT_FTP_PASS}"
fi

# Add an SSH key, if provided, to the ssh-agent
if [ -n "${INPUT_SSH_PRIVATE_KEY}" ]; then
	TMP_SSH_KEY_FILE=$(mktemp)
	echo "${INPUT_SSH_PRIVATE_KEY}" > "${TMP_SSH_KEY_FILE}"
	eval "$(ssh-agent)"
	ssh-add "${TMP_SSH_KEY_FILE}"
	rm -f "${TMP_SSH_KEY_FILE}"
	export INPUT_SSH_PRIVATE_KEY="" && unset INPUT_SSH_PRIVATE_KEY
fi

SFTP_AUTO_CONFIRM="false"
STRICT_HOST_KEY_CHECKING="yes"
KNOWN_HOSTS_FILE="/dev/null"

if [ -n "${INPUT_FTP_HOST_FINGERPRINT}" ]; then
	KNOWN_HOSTS_FILE="$(mktemp)"
	STRICT_HOST_KEY_CHECKING="yes"
	echo "${INPUT_FTP_HOST} ${INPUT_FTP_HOST_FINGERPRINT}" > "${KNOWN_HOSTS_FILE}"
elif [ "${INPUT_DISABLE_STRICT_HOST_KEY_CHECKING}" = "true" ]; then
	STRICT_HOST_KEY_CHECKING="no"
	SFTP_AUTO_CONFIRM="true"
fi

# Configure SSH for lftp
SSH_OPTIONS="-o GlobalKnownHostsFile=/dev/null"
SSH_OPTIONS="-o UserKnownHostsFile=${KNOWN_HOSTS_FILE} ${SSH_OPTIONS}"
SSH_OPTIONS="-o StrictHostKeyChecking=${STRICT_HOST_KEY_CHECKING} ${SSH_OPTIONS}"

LFTP_OPTIONS="set sftp:auto-confirm ${SFTP_AUTO_CONFIRM};"
LFTP_OPTIONS="set sftp:connect-program /usr/bin/ssh -a -x ${SSH_OPTIONS}; ${LFTP_OPTIONS}"
LFTP_OPTIONS="set net:max-retries 1; ${LFTP_OPTIONS}"
LFTP_OPTIONS="set net:persist-retries 0; ${LFTP_OPTIONS}"
LFTP_OPTIONS="set ftp:ssl-force ${FTP_FORCE_SSL}; ${LFTP_OPTIONS}"
LFTP_OPTIONS="set ssl:verify-certificate ${SSL_VERIFY_CERT}; ${LFTP_OPTIONS}"

if [ -n "${LFTP_PASSWORD}" ]; then
	[ "${INPUT_DEBUG}" = 'true' ] && set -x
	lftp --norc -u "${FTP_USER}" --env-password -p "${FTP_PORT}" -e "${LFTP_OPTIONS} ${INPUT_COMMANDS}; bye" "${FTP_PROTOCOL}://${INPUT_FTP_HOST}"
else
	[ "${INPUT_DEBUG}" = 'true' ] && set -x
	lftp --norc -u "${FTP_USER}" -p "${FTP_PORT}" -e "${LFTP_OPTIONS} ${INPUT_COMMANDS}; bye" "${FTP_PROTOCOL}://${INPUT_FTP_HOST}"
fi
