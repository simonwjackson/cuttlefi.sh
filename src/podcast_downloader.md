# PODCAST_DOWNLOADER(1) User Manuals
## NAME
`podcast_downloader` - script to download podcast episodes based on a YAML configuration file

## SYNOPSIS
**podcast_downloader** [command] [options]

## DESCRIPTION
`podcast_downloader` is a shell script designed to download podcast episodes automatically. It uses a YAML configuration file to read podcast subscriptions and saves downloaded episodes and logs in specified directories. The script requires xmlstarlet, yq, wget, and md5sum to be installed on the system.

## COMMANDS
### sync
Synchronize podcasts based on the configuration file. This command triggers the core functionality of the script, downloading all episodes for each podcast listed in the configuration file.

## OPTIONS
- **--log-level [level]**
  Sets the logging level for the script. Acceptable values are "info", "warn", and "error". The default level is "info".

- **--help**
  Displays the usage information for the script.

## FILES
- **/tmp/podcast_config.yaml**
  The YAML configuration file containing podcast subscriptions. Each subscription should include the podcast name and its RSS feed URL.

- **./podcast_episodes**
  Directory where the downloaded podcast episodes are saved.

- **./download_logs**
  Directory where the download logs are stored.

## EXAMPLES
To synchronize podcasts with default log level:

    podcast_downloader sync

To synchronize podcasts with a specific log level:

    podcast_downloader sync --log-level warn

To display help information:

    podcast_downloader --help

## AUTHOR
Written by [Your Name].

## SEE ALSO
`wget(1)`, `yq(1)`, `xmlstarlet(1)`, `md5sum(1)`
