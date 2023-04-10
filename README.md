# lftp-action

A simple action that allows you to use [LFTP](https://lftp.yar.ru) securely in a GitHub workflow. 
Useful to deploy code to a server over SFTP.

## Inputs

| Name                             | Description                                                                                                             | Required | Default   |
|----------------------------------|-------------------------------------------------------------------------------------------------------------------------|----------|-----------|
| ftp_host                         | The hostname to connect to                                                                                              | yes      | N/A       |
| ftp_user                         | FTP username                                                                                                            | no       | anonymous |
| ftp_pass                         | FTP password if required                                                                                                | no       | N/A       |
| ftp_port                         | FTP port                                                                                                                | no       | 22        |
| ssh_private_key                  | SSH private key which will be used when connecting over SFTP                                                            | no       | N/A       |
| ftp_protocol                     | What protocol to use; `sftp`, `ftp`                                                                                     | no       | sftp      |
| ftp_host_fingerprint             | The SSH host fingerprint to verify when connecting                                                                      | no       | N/A       |
| disable_strict_host_key_checking | Disable `StrictHostKeyChecking` (not recommended)                                                                       | no       | false     |
| force_ssl                        | if true, refuse to send password in clear when server does not support SSL                                              | no       | true      |
| ssl_verify_cert                  | when true, `lftp` checks if the host name used to connect to the server corresponds to the host name in its certificate | no       | true      |
| commands                         | All commands for `lftp` seperated with `;`                                                                              | no       | ''        |
| debug                            | Turn on debug mode                                                                                                      | no       | false     |

## Basic usage

```yaml
name: Deploy via SFTP
on:
  push:
    branches:
      - main
jobs:
  deploy:
    name: Deploy website
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      # Build steps ...

      - name: Deploy files via SFTP
        uses: haukurh/lftp-action@v1
        with:
          ftp_host: ${{ vars.FTP_HOST }}
          ftp_user: ${{ vars.FTP_USER }}
          ftp_pass: ${{ secrets.FTP_PASS }}
          ftp_host_fingerprint: ${{ vars.FTP_HOST_FINGERPRINT }}
          commands: mirror --continue --reverse --delete --verbose app/ /remote/www/site/
```

## Useful recipes

### Only sync modified files

```yaml
name: Deploy via SFTP
on:
  push:
    branches:
      - main
jobs:
  deploy:
    name: Deploy website
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        # We disable shallow fetch in order to have all the history for next step
        with:
          fetch-depth: 0
        
        # Fix file modified date according to git commit history
      - name: Fix file modified date
        run: git ls-files | xargs -I{} git log -1 --date=format:%Y%m%d%H%M.%S --format='touch -t %ad "{}"' "{}" | $SHELL

        # Mirror all the files from app/ folder to the server
        # Warning: this will delete everything else on the server that's not included in the mirror
      - name: Deploy files via SFTP
        uses: haukurh/lftp-action@v1
        with:
          ftp_host: ${{ vars.FTP_HOST }}
          ftp_user: ${{ vars.FTP_USER }}
          ftp_pass: ${{ secrets.FTP_PASS }}
          ftp_host_fingerprint: ${{ vars.FTP_HOST_FINGERPRINT }}
          commands: mirror --continue --reverse --delete --verbose app/ /remote/www/site/
```

### SSH Key-Based Authentication

Instead of using user + password to authenticate over SSH you should use SSH Key-Based Authentication.

```yaml
name: Deploy via SFTP
on:
  push:
    branches:
      - main
jobs:
  deploy:
    name: Deploy website
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      # Build steps ...

      - name: Deploy files via SFTP
        uses: haukurh/lftp-action@v1
        with:
          ftp_host: ${{ vars.FTP_HOST }}
          ftp_user: ${{ vars.FTP_USER }}
          ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
          ftp_host_fingerprint: ${{ vars.FTP_HOST_FINGERPRINT }}
          commands: mirror --continue --reverse --delete --verbose app/ /remote/www/site/
```

### Disable strict host key checking

Although not recommended this could be necessary in some cases.

```yaml
name: Deploy via SFTP
on:
  push:
    branches:
      - main
jobs:
  deploy:
    name: Deploy website
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      # Build steps ...

      - name: Deploy files via SFTP
        uses: haukurh/lftp-action@v1
        with:
          ftp_host: ${{ vars.FTP_HOST }}
          ftp_user: ${{ vars.FTP_USER }}
          ftp_pass: ${{ secrets.FTP_PASS }}
          disable_strict_host_key_checking: "true"
          commands: mirror --continue --reverse --delete --verbose app/ /remote/www/site/
```

## LFTP

> LFTP is a sophisticated file transfer program supporting a number of network protocols (ftp, http, sftp, fish, torrent).

This action uses LFTP behind the scenes, LFTP is really powerful so it's best to check out the man pages for more 
in depth information about the available commands.

- LFTP website: [lftp.yar.ru](https://lftp.yar.ru)
- LFTP man page: [lftp.yar.ru/lftp-man](https://lftp.yar.ru/lftp-man.html)
- LFTP GitHub repo: [github.com/lavv17/lftp](https://github.com/lavv17/lftp)

## Issues

If you find any problems with this GitHub action, please [open an issue](https://github.com/haukurh/lftp-action/issues).

## License

The MIT License, check the `LICENSE` file.
