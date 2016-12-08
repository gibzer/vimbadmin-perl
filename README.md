# vimbadmin-perl

Scripts to automate some actions with ViMbAdmin:

    - create mailboxes;
    - create aliases;
    - delete aliases;
    - change passwords.

Perl dependencies:

    - DBI.

External utilities dependencies:

    - doveadm (for creating passwords with selected password scheme).

They do what is expected, except adding a record to log table.
Adjust database settings in scripts (plus mail paths in "create mailboxes" script).
Read input format in the beginning of script (field delimiter is tabulation).

Usage:

    ./script file_with_data
    echo "data" | ./script

## Additional scripts:

    - find wrong aliases;
    - update mailbox size.

find_wrong_aliases.pl finds wrong aliases which are pointing to not existent mailbox or alias.

Usage:

    ./find_wrong_aliases.pl [-f]

Options:

    -f Prints info about all aliases instead of only wrong ones.

update_mailbox_size.pl updates all mailboxes size. If possible, it uses 'maildirsize' file instead of just using 'du'.
You may choose what type of 'du' to use: Perl (requires Filesys::DiskUsage module) or system (see script).

Usage:

    ./update_mailbox_size.pl
