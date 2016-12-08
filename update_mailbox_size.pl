#!/usr/bin/perl

use strict;
use warnings;
no if ( $] >= 5.018 ), warnings => "experimental::smartmatch";
use DBI;
use POSIX qw(strftime);
### Comment next line if using system du
use Filesys::DiskUsage qw(du);
my $du_type = 1;
# 1 - Perl du
# 0 - system du
###

### Database settings
my $driver   = "mysql";
my $database = "vimbadmin";
my $host     = "localhost";
my $port     = "3306";
my $username = "";
my $password = "";
###

my $dbh
    = DBI->connect( "dbi:$driver:database=$database;host=$host;port=$port",
    $username, $password )
    or die "Unable to connect: $DBI::errstr\n";

my $sth = $dbh->prepare("SELECT id,username,homedir,maildir FROM mailbox");
$sth->execute() or die "Query error: $DBI::errstr\n";

while ( my @row = $sth->fetchrow_array ) {
    my ( $id, $username, $homedir, $maildir ) = @row;

    $maildir = ( split( ":", $maildir ) )[1];

    ( my $exclude_dir = $maildir ) =~ s/$homedir//;
    $exclude_dir =~ s:^/::;

    my $homedir_size = 0;
    if ( -d $homedir ) {
        if ($du_type) {
            $homedir_size = du( { exclude => qr/^$exclude_dir/ }, $homedir );
        }
        else {
            chomp( $homedir_size
                    = `du -bs --exclude="$exclude_dir" "$homedir"` );
            $homedir_size = ( split( /\t/, $homedir_size ) )[0];
        }
    }

    my $maildir_size          = 0;
    my $maildirsize_file_name = "$maildir/maildirsize";
    if ( -f $maildirsize_file_name ) {
        open my $maildirsize_file, "<", $maildirsize_file_name
            or die "Can't open file: $!";
        while (<$maildirsize_file>) {
            if (/^(-?\d+) -?\d+$/) { $maildir_size += $1; }
        }
        close $maildirsize_file;
    }
    else {
        if ( -d $maildir ) {
            if ($du_type) { $maildir_size = du($maildir); }
            else {
                chomp( $maildir_size = `du -bs "$maildir"` );
                $maildir_size = ( split( /\t/, $maildir_size ) )[0];
            }
        }
    }

    my $size_at = strftime( "%Y-%m-%d %H:%M:%S", localtime() );

    my $sth_upd
        = $dbh->prepare(
        "UPDATE mailbox SET homedir_size = ?, maildir_size = ?, size_at = ? WHERE id = ?"
        );
    $sth_upd->execute( $homedir_size, $maildir_size, $size_at, $id )
        or die "Query error: $DBI::errstr\n";
}
