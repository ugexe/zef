use v6;
LEAVE {
    say "\n[HOOK: {$*PROGRAM.basename}] launched OK";

    exit 0;
}