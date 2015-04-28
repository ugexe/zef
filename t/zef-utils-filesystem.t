use v6;
use Zef::Utils::FileSystem;
plan 4;
use Test;

# :d :f :r
subtest {
    my @delete-us;

    # 1. Folder: /tmp/{time}
    # 2. File:   /tmp/{time}/base-delete.me 
    # 3. Folder: /tmp/{time}/deleteme-subfolder
    # 4. File:   /tmp/{time}/deleteme-subfolder/base-delete.me
    # All 4 items should get deleted

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
}, ".ls and .rm :d :f :r (rm -rf)";


# :d :f
subtest {
    my @delete-us;

    # 1. Folder: /tmp/{time}
    # 2. File:   /tmp/{time}/base-delete.me 
    # 3. Folder: /tmp/{time}/deleteme-subfolder
    # 4. File:   /tmp/{time}/deleteme-subfolder/base-delete.me
    # Only item 2 should get deleted

    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdir($save-to);
    my $sub-folder = $*SPEC.catdir($save-to, 'deleteme-subfolder');
    try mkdir($sub-folder);

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $*SPEC.catpath('', $save-to, 'base-delete.me');
    my $sub-folder-file = $*SPEC.catpath('', $sub-folder, 'sub-delete.me');
    @delete-us.push($save-to-file) if try open($save-to-file, :w);
    try open($sub-folder-file, :w);

    my $fs;
    ok $save-to.IO.d, "Folder available to delete";
    lives_ok { $fs = Zef::Utils::FileSystem.new( path => $save-to // die ) }, 
        'Created new Zef::Utils::FileSystem object';

    my @ls      = $fs.ls(:d, :f);
    my @deleted = $fs.rm(:d, :f);

    my $to-be-deleted = any($save-to-file);
    my $not-deleted   = any($save-to, $sub-folder, $sub-folder-file);
    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(@ls), 'file was found in .ls';
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.IO.path}";
        isnt $path-to-delete, $not-deleted, 'Did not delete sub-file or delete non-empty directory';
    }

    # deletion doesn't always happen immediately
    #is $save-to.IO.e, False, "Folder deleted"; 
}, ".ls and .rm :d :f (no recursion)";


# :d :r
subtest {
    my @delete-us;

    # 1. Folder: /tmp/{time}
    # 2. File:   /tmp/{time}/base-delete.me 
    # 3. Folder: /tmp/{time}/deleteme-subfolder
    # 4. File:   /tmp/{time}/deleteme-subfolder/base-delete.me
    # 5. Folder  /tmp/{time}/empty-subfolder
    # Only item 5 will be deleted

    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdir($save-to);
    my $sub-folder = $*SPEC.catdir($save-to, 'deleteme-subfolder');
    try mkdir($sub-folder);
    my $sub-folder-empty = $*SPEC.catdir($save-to, 'empty-subfolder');
    @delete-us.push($sub-folder-empty) if try mkdir($sub-folder-empty);

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $*SPEC.catpath('', $save-to, 'base-delete.me');
    my $sub-folder-file = $*SPEC.catpath('', $sub-folder, 'sub-delete.me');
    try open($save-to-file, :w);
    try open($sub-folder-file, :w);

    my $fs;
    ok $save-to.IO.d, "Folder available to delete";
    lives_ok { $fs = Zef::Utils::FileSystem.new( path => $save-to // die ) }, 
        'Created new Zef::Utils::FileSystem object';

    my @ls      = $fs.ls(:d, :r);
    my @deleted = $fs.rm(:d, :r);

    my $to-be-deleted = any($sub-folder-empty);
    my $not-deleted   = any($save-to, $save-to-file, $sub-folder, $sub-folder-file);
    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(@ls), 'file was found in .ls';
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.IO.path}";
        isnt $path-to-delete, $not-deleted, 'Did not delete sub-file or delete non-empty directory';
    }

    # deletion doesn't always happen immediately
    #is $save-to.IO.e, False, "Folder deleted"; 
}, ".ls and .rm :d :r";


# :f :r
subtest {
    my @delete-us;

    # 1. Folder: /tmp/{time}
    # 2. File:   /tmp/{time}/base-delete.me 
    # 3. Folder: /tmp/{time}/deleteme-subfolder
    # 4. File:   /tmp/{time}/deleteme-subfolder/base-delete.me
    # 5. Folder  /tmp/{time}/empty-subfolder
    # Delete items 2 and 4

    my $save-to = $*SPEC.catdir($*TMPDIR, time).IO;
    try mkdir($save-to);
    my $sub-folder = $*SPEC.catdir($save-to, 'deleteme-subfolder');
    try mkdir($sub-folder);
    my $sub-folder-empty = $*SPEC.catdir($save-to, 'empty-subfolder');
    try mkdir($sub-folder-empty);

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $*SPEC.catpath('', $save-to, 'base-delete.me');
    my $sub-folder-file = $*SPEC.catpath('', $sub-folder, 'sub-delete.me');
    @delete-us.push($save-to-file) if try open($save-to-file, :w);
    @delete-us.push($sub-folder-file) if try open($sub-folder-file, :w);

    my $fs;
    ok $save-to.IO.d, "Folder available to delete";
    lives_ok { $fs = Zef::Utils::FileSystem.new( path => $save-to // die ) }, 
        'Created new Zef::Utils::FileSystem object';

    my @ls      = $fs.ls(:f, :r);
    my @deleted = $fs.rm(:f, :r);

    my $to-be-deleted = any($save-to-file, $sub-folder-file);
    my $not-deleted   = any($save-to, $sub-folder, $sub-folder-empty);
    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(@ls), 'file was found in .ls';
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.IO.path}";
        isnt $path-to-delete, $not-deleted, 'Did not delete sub-file or delete non-empty directory';
    }

    # deletion doesn't always happen immediately
    #is $save-to.IO.e, False, "Folder deleted"; 
}, ".ls and .rm :f :r";

