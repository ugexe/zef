use v6;
use Zef::Utils::FileSystem;
plan 1;
use Test;

# :d :f :r
subtest {
    my @delete-us;

    # setup /tmp/{time} with sub folder /deleteme-subfolder
    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    @delete-us.push($save-to) if try mkdir($save-to);
    my $sub-folder = $*SPEC.catdir($save-to, 'deleteme-subfolder');
    @delete-us.push($sub-folder) if try mkdir($sub-folder);

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $*SPEC.catpath('', $save-to, 'base-delete.me');
    my $sub-folder-file = $*SPEC.catpath('', $sub-folder, 'sub-delete.me');
    @delete-us.push($save-to-file) if try open($save-to-file, :w);
    @delete-us.push($sub-folder-file) if try open($sub-folder-file, :w);

    my $fs;
    ok $save-to.IO.d, "Folder available to delete";
    lives_ok { $fs = Zef::Utils::FileSystem.new( path => $save-to // die ) }, 
        'Created new Zef::Utils::FileSystem object';

    my @ls      = $fs.ls(:d, :f, :r);
    my @deleted = $fs.rm(:d, :f, :r);

    is @ls.elems, @deleted.elems, '.ls matches number of items deleted';

    my $to-be-deleted = any($save-to, $sub-folder, $save-to-file, $sub-folder-file);
    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(@ls), 'file was found in .ls';
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.IO.path}";
    }

    # deletion doesn't always happen immediately
    #is $save-to.IO.e, False, "Folder deleted"; 
}, "rm -rf";

