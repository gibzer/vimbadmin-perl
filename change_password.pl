#!/usr/bin/perl

# ./$0 "USERNAME	PASSWORD"

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
### Password scheme
my $password_scheme = "SHA512-CRYPT";
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
    if (/^(\S+@\S+)\t(.+)$/) {
        my ( $username, $userpass ) = ( $1, $2 );

        my $exists = 0;
        $sth
            = $dbh->prepare("SELECT created FROM mailbox WHERE username = ?");
        $sth->execute($username) or die "Query error: $DBI::errstr\n";
        while ( my @row = $sth->fetchrow_array ) { $exists = 1; }

        if ($exists) {
            printf "Changing password for mailbox %s...",
                colored( $username, "green" );
            chomp( my $userpass_crypted
                    = `doveadm pw -s "$password_scheme" -p "$userpass"` );
            $userpass_crypted =~ s/^{$password_scheme}//;
            $sth = $dbh->prepare(
                "UPDATE mailbox SET password = ? WHERE username = ?");
            $sth->execute( $userpass_crypted, $username )
                or die "Query error: $DBI::errstr\n";
            print " Done\n";
        }
        else {
            printf "Mailbox %s doesn't exist\n", colored( $username, "red" );
        }
    }
}
