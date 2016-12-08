#!/usr/bin/perl

# ./$0 "USERNAME	PASSWORD	NAME	QUOTA (in bytes)"

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
### Password scheme
my $password_scheme = "SHA512-CRYPT";
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
    if (/^((\S+)@(\S+))\t(.+)\t(.*)\t(\d+)$/) {
        my ( $username, $local_part, $domain, $userpass, $name, $quota )
            = ( $1, $2, $3, $4, $5, $6 );
        my $alt_email = "";
        my $active    = "1";
        ### Paths for mailbox, UID, GID
        my $homedir = "/var/vmail/${domain}/${local_part}";
        my $maildir
            = "maildir:/var/vmail/${domain}/${local_part}/mail:LAYOUT=fs";
        my $uid = "150";
        my $gid = "8";
        ###
        my $created = strftime( "%Y-%m-%d %H:%M:%S", localtime() );

        my $exists = 0;
        $sth
            = $dbh->prepare("SELECT created FROM mailbox WHERE username = ?");
        $sth->execute($username) or die "Query error: $DBI::errstr\n";
        while ( my @row = $sth->fetchrow_array ) { $exists = 1; }

        if ($exists) {
            printf "Mailbox %s already exists. Skipping\n",
                colored( $username, "red" );
            next;
        }

        $sth = $dbh->prepare("SELECT created FROM alias WHERE address = ?");
        $sth->execute($username) or die "Query error: $DBI::errstr\n";
        while ( my @row = $sth->fetchrow_array ) { $exists = 1; }

        if ($exists) {
            printf "Alias %s already exists. Can't create mailbox\n",
                colored( $username, "red" );
            next;
        }

        if ( exists( $domains_id{$domain} )
            and defined( $domains_id{$domain} ) )
        {
            printf "Creating mailbox %s, name %s, quota %s B...",
                colored( $username, "green" ), colored( $name, "blue" ),
                colored( $quota, "cyan" );
            chomp( my $userpass_crypted
                    = `doveadm pw -s "$password_scheme" -p "$userpass"` );
            $userpass_crypted =~ s/^{$password_scheme}//;

            $sth
                = $dbh->prepare(
                "INSERT INTO mailbox (username,password,name,alt_email,quota,local_part,active,homedir,maildir,uid,gid,created,Domain_id) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)"
                );
            $sth->execute(
                $username, $userpass_crypted,
                $name,     $alt_email,
                $quota,    $local_part,
                $active,   $homedir,
                $maildir,  $uid,
                $gid,      $created,
                $domains_id{$domain}
            ) or die "Query error: $DBI::errstr\n";

            $sth
                = $dbh->prepare(
                "INSERT INTO alias (address,goto,created,Domain_id) VALUES (?,?,?,?)"
                );
            $sth->execute( $username, $username, $created,
                $domains_id{$domain} )
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
            printf "Domain %s doesn't exist. Can't create mailbox %s\n",
                colored( $domain, "yellow" ), colored( $username, "red" );
        }
    }
}
