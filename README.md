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

    - find wrong aliases.

find_wrong_aliases.pl finds wrong aliases which are pointing to not existent mailbox or alias.

Usage:

    ./find_wrong_aliases.pl [-f]

Options:

    -f Prints info about all aliases instead of only wrong ones.
