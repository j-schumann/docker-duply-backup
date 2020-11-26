# docker-duply-backup

Docker container using Duply to backup data mounted via volume.
This container with its default settings auto-creates a duply profile with the default settings for you
and backups the volume you mounted once per day. It also creates a GPG key for encrypting the backup if you

## Volumes

* `/etc/duply` - mount a volume here to store the generated duply profile (default name: data)
  or provide a customized config (maybe including pre-script), must also be named "data"
* `/gpg` - mount a volume here to store the generated GPG key so it persists when the container is recreated
* `/backup` - mount the folder containing all files & folders you want to backup here
* optional: `/var/spool/cron/crontabs/root` - mount a custom crontab file here to overwrite the default schedule (daily backups) 
  must not contain the username (see file `crontab` for example)

## Environment Variables

* GPG_PASSPHRASE - set this if you don't want to use a random passphrase when a GPG key is generated (only on the first run) 
  The generated passphrase can later be inspected in the volume you used to mount on `/etc/duply` in the `data/conf` file
* BACKUP_TARGET - set to the endpoint supported by duplicity, e.g. something like "ftp://user:password@host.tld/path/to/backup"

## Customization

* after the default Duply profile was created you can modify the settings, e.g. number of full backups to keey, max age etc..
  This can be done in the folder you mounted as `/etc/duply` in the `data/conf` file.
* if you already have a GPG key you want to use provide the compatible keychain to the `/gpg` mount or import your key manually
  by using `docker run ...` or `docker exec ...` and set the key ID & passphrase afterwards in the duply profile
* provide a customized crontab file to use a different schedule, e.g. backup every 3 hours
* add a shell script named `pre` (must be executable) to the folder you mounted as `/etc/duply`, this can create database dumps
  and store them in the /backup folder before Duply runs
* instead of starting the container as background service using cron you can also use it to only run when requested by providing the command to run. 
  E.g. to manually trigger a backup use:
  `docker run -v [changeme]:/etc/duply -v [changeme]:/gpg -v [changeme]:/backup -e BACKUP_TARGET=[changeme] jschumann/docker-duply-backup:latest duply data backup`