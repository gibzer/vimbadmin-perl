#!/usr/bin/perl

# ./$0 "ALIAS"

use strict;
use warnings;
no if ( $] >= 5.018 ), warnings => "experimental::smartmatch";
use DBI;
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
my $sth;

my $dbh
    = DBI->connect( "dbi:$driver:database=$database;host=$host;port=$port",
    $username, $password )
    or die "Unable to connect: $DBI::errstr\n";

while (<>) {
    chomp;
    if ( $_ ~~ @empty_string ) { next; }
    if (/^(\S+@(\S+))$/) {
        my ( $alias, $domain ) = ( $1, $2 );

        my $domain_id;
        $sth = $dbh->prepare("SELECT Domain_id FROM alias WHERE address = ?");
        $sth->execute($alias) or die "Query error: $DBI::errstr\n";
        while ( my @row = $sth->fetchrow_array ) { ($domain_id) = @row; }

        if ( defined($domain_id) ) {
            printf "Deleting alias %s...", colored( $alias, "green" );
            $sth = $dbh->prepare("DELETE FROM alias WHERE address = ?");
            $sth->execute($alias) or die "Query error: $DBI::errstr\n";
            $sth
                = $dbh->prepare(
                "UPDATE domain SET alias_count = alias_count - 1 WHERE id = ?"
                );
            $sth->execute($domain_id) or die "Query error: $DBI::errstr\n";
            print " Done\n";
        }
        else { printf "Alias %s doesn't exist\n", colored( $alias, "red" ); }
    }
}
