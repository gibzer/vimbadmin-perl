#!/usr/bin/perl

# ./$0 "ALIAS	ALIAS_TO[,ALIAS_TO_1...]"

use strict;
use warnings;
no if ( $] >= 5.018 ), warnings => "experimental::smartmatch";
use DBI;
use POSIX qw(strftime);
use Term::ANSIColor;

### Database settings
my $driver   = "mysql";
my $database = "vimbadmin";
my $host     = "localhost";
my $port     = "3306";
my $username = "";
my $password = "";
###

my @empty_string = ( qr/^$/, qr/^\s*#/ );

my $dbh
    = DBI->connect( "dbi:$driver:database=$database;host=$host;port=$port",
    $username, $password )
    or die "Unable to connect: $DBI::errstr\n";

my %domains_id;
my $sth = $dbh->prepare("SELECT domain,id FROM domain");
$sth->execute() or die "Query error: $DBI::errstr\n";
while ( my @row = $sth->fetchrow_array ) { $domains_id{ $row[0] } = $row[1]; }

while (<>) {
    chomp;
    if ( $_ ~~ @empty_string ) { next; }
    if (/^(\S+@(\S+))\t(\S+@\S+)$/) {
        my ( $alias, $domain, $alias_to ) = ( $1, $2, $3 );
        my $created = strftime( "%Y-%m-%d %H:%M:%S", localtime() );

        my $exists = 0;
        $sth = $dbh->prepare("SELECT created FROM alias WHERE address = ?");
        $sth->execute($alias) or die "Query error: $DBI::errstr\n";
        while ( my @row = $sth->fetchrow_array ) { $exists = 1; }
        if ($exists) {
            printf "Alias %s already exists. Skipping\n",
                colored( $alias, "red" );
            next;
        }

        if ( exists( $domains_id{$domain} )
            and defined( $domains_id{$domain} ) )
        {
            printf "Creating alias %s -> %s...", colored( $alias, "green" ),
                colored( $alias_to, "bright_magenta" );
            $sth
                = $dbh->prepare(
                "INSERT INTO alias (address,goto,created,Domain_id) VALUES (?,?,?,?)"
                );
            $sth->execute( $alias, $alias_to, $created, $domains_id{$domain} )
                or die "Query error: $DBI::errstr\n";
            $sth
                = $dbh->prepare(
                "UPDATE domain SET alias_count = alias_count + 1 WHERE id = ?"
                );
            $sth->execute( $domains_id{$domain} )
                or die "Query error: $DBI::errstr\n";
            print " Done\n";
        }
        else {
            printf "Domain %s doesn't exist. Can't create alias %s\n",
                colored( $domain, "yellow" ), colored( $alias, "red" );
        }
    }
}
