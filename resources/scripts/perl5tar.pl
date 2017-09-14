use Archive::Tar;

if( !defined $ARGV[0] ) {
	exit 1;
}
elsif( $ARGV[0] eq '--help' ) {
	print "List files: <command> --list <path-to-archive>\n";
	print "Extract files: <command> <path-to-archive>\n";
	exit 0;
}
elsif( $ARGV[0] eq '--list' ) {
    my $extractor = Archive::Tar->new();
    $extractor->read($ARGV[1]);
    print "$_\n" for( $extractor->list_files() );
    exit 0;
}
else {
    my $extractor = Archive::Tar->new();
    $extractor->read($ARGV[0]);
    $extractor->extract();
    exit 0;
}
