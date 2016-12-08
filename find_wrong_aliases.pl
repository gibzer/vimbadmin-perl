#!/usr/bin/perl

use strict;
use warnings;
use feature "switch";
no if ( $] >= 5.018 ), warnings => "experimental::smartmatch";
use Term::ANSIColor;
use DBI;

### Database settings
my $driver   = "mysql";
my $database = "vimbadmin";
my $host     = "localhost";
my $port     = "3306";
my $username = "";
my $password = "";
###

sub type_color {
    my $type = shift;
    my $type_color;
    given ($type) {
        when ("MAILBOX")   { $type_color = "green"; }
        when ("ALIAS")     { $type_color = "bright_green"; }
        when ("EXT_ALIAS") { $type_color = "yellow"; }
        when ("WRONG")     { $type_color = "red"; }
        default            { $type_color = "bright_red"; }
    }
    return $type_color;
}

my $full = 0;
if ( defined( $ARGV[0] ) and ( $ARGV[0] eq "-f" ) ) { $full = 1; }

my $dbh
    = DBI->connect( "dbi:$driver:database=$database;host=$host;port=$port",
    $username, $password )
    or die "Unable to connect: $DBI::errstr\n";

my @domains;
my $sth = $dbh->prepare("SELECT domain FROM domain");
$sth->execute() or die "Query error: $DBI::errstr\n";
while ( my @row = $sth->fetchrow_array ) {
    my $domain = '@' . $row[0] . '$';
    push @domains, qr/$domain/;
}

my @mailboxes;
$sth = $dbh->prepare("SELECT username FROM mailbox");
$sth->execute() or die "Query error: $DBI::errstr\n";
while ( my @row = $sth->fetchrow_array ) { push @mailboxes, $row[0]; }

my %aliases;
$sth = $dbh->prepare("SELECT address,goto FROM alias");
$sth->execute() or die "Query error: $DBI::errstr\n";
while ( my @row = $sth->fetchrow_array ) {
    my ( $address, $goto ) = @row;
    $aliases{$address}->{'gotos'}
        = { map { $_ => "null" } split( ",", $goto ) };
}

foreach my $address ( sort keys %aliases ) {
    if ($full) { printf "%s\n", colored( $address, "bold blue" ); }
    foreach my $goto ( sort keys %{ $aliases{$address}->{'gotos'} } ) {
        if ( $goto ~~ @mailboxes ) {
            $aliases{$address}->{'gotos'}->{$goto} = "MAILBOX";
        }
        elsif ( not( $goto ~~ @domains ) ) {
            $aliases{$address}->{'gotos'}->{$goto} = "EXT_ALIAS";
        }
        elsif ( $goto ~~ [ keys %aliases ] ) {
            $aliases{$address}->{'gotos'}->{$goto} = "ALIAS";
        }
        else { $aliases{$address}->{'gotos'}->{$goto} = "WRONG"; }
        if ($full) {
            printf "\t%s\t%s\n", colored( $goto, "bright_magenta" ),
                colored( $aliases{$address}->{'gotos'}->{$goto},
                type_color( $aliases{$address}->{'gotos'}->{$goto} ) );
        }
    }
}

if ( not $full ) {
NEXT: foreach my $address ( sort keys %aliases ) {
        foreach my $goto ( sort keys %{ $aliases{$address}->{'gotos'} } ) {
            if ( $aliases{$address}->{'gotos'}->{$goto} eq "WRONG" ) {
                printf "%s\n", colored( $address, "bold blue" );
                foreach
                    my $goto ( sort keys %{ $aliases{$address}->{'gotos'} } )
                {
                    printf "\t%s\t%s\n", colored( $goto, "bright_magenta" ),
                        colored(
                        $aliases{$address}->{'gotos'}->{$goto},
                        type_color( $aliases{$address}->{'gotos'}->{$goto} )
                        );
                }
                next NEXT;
            }
        }
    }
}
