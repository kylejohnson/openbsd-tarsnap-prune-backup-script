!/usr/bin/perl

use strict;
use warnings;

# Set $keep to the number of days to keep backups for
my $days = 5;
# Set $location to the directory to backup, e.g. '/' for root
my $location = '/';

# Don't change anything below here.
my $keep = (60*60*24*$days);
chomp(my $date = `date +%s`);
chomp(my $hostname = `hostname`);

logger('Starting backup.');

unless ($date && $hostname) {
        logger('Could not determine date or hostname.', 1);
}

unless ($days >= 1) {
        logger('You must keep at least 1 day of backups.', 1);
}

do_backup();

if ($? > 0) {
        logger('Backup failed.', 1);
} else {
        logger('Backup was successful.');
        prune_archives();
}

sub do_backup {
        my @args = ('/usr/local/bin/tarsnap', '--exclude', '/dev', '-cf', "$hostname.root.$date", "$location");
        system(@args);
}

sub logger {
        my $msg = $_[0];
        my $death = $_[1];
        my $tag = 'tarsnap-backup.sh';
        system("logger -t $tag $msg");

        if ($death) {
                die($msg);
        }
}

sub prune_archives {
        my @archives = list_archives();

        foreach my $archive (@archives) {
                chomp($archive);
                my @values = split('\.', $archive);
                my $epoch = $values[4];
                my $diff = ($date - $epoch);
                
                if ($diff > $keep) {
                        delete_archive($archive);
                }
        }
}

sub list_archives {
        my @archives = `/usr/local/bin/tarsnap --list-archives`;

        logger("Could not retrieve list of archives.", 1) if ($? > 0);

        return @archives;
}

sub delete_archive {
        my $archive = $_[0] or logger('Not a valid archive.', 1);

        logger("Deleting $archive");

        my @args = ('/usr/local/bin/tarsnap', '-d', '-f', "$archive");
        system(@args);

        if ($? == 0) {
                logger("Archive $archive successfully deleted.");
        } else {
                logger("Archive $archive could not be deleted.");
        }
}
