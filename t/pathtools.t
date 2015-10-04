use v6;
use PathTools;

use Test;
plan 5;

subtest {
    my $save-to = mktemp();
    my $sub-save-to     = $save-to.IO.child('sub1');
    my $sub-sub-save-to = $sub-save-to.IO.child('sub2');
    my $created-dir     = mkdirs($sub-sub-save-to);

    ok (~$sub-sub-save-to).IO.e, "Created {$sub-sub-save-to}";
    is $created-dir.IO.path, $sub-sub-save-to.IO.path, 'Proper directory path';
}, 'mkdirs';

# :d :f :r
subtest {
    my @delete-us;

    # 1. Folder: /{temp folder}
    # 2. File:   /{temp folder}/base-delete.me 
    # 3. Folder: /{temp folder}/deleteme-subfolder
    # 4. File:   /{temp folder}/deleteme-subfolder/base-delete.me
    # All 4 items should get deleted

    my $save-to = mktemp();

    @delete-us.append(mkdirs(~$save-to));
    my $sub-folder = $save-to.IO.child('deleteme-subfolder').IO;
    @delete-us.append(mkdirs(~$sub-folder));

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $save-to.IO.child('base-delete.me').IO;
    my $sub-folder-file = $sub-folder.IO.child('sub-delete.me').IO;
    @delete-us.append($save-to-file.IO.path) if open($save-to-file.IO.path, :w);
    @delete-us.append($sub-folder-file.IO.path) if open($sub-folder-file.IO.path, :w);

    ok $save-to.IO.d, "Folder available to delete";

    my @ls      = ls($save-to, :f, :d, :r);
    my @deleted = rm($save-to, :f, :d, :r);

    my $to-be-deleted = any($save-to, $sub-folder, $save-to-file, $sub-folder-file);
    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(|@ls,$save-to), 'file was found in .ls';
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.IO.path}";
    }

    # deletion doesn't always happen immediately
    # is $save-to.IO.e, False, "Folder deleted"; 
}, ".ls and .rm :d :f :r (rm -rf)";


# :d :f
subtest {
    my @delete-us;

    # 1. Folder: /{temp folder}
    # 2. File:   /{temp folder}/base-delete.me 
    # 3. Folder: /{temp folder}/deleteme-subfolder
    # 4. File:   /{temp folder}/deleteme-subfolder/base-delete.me
    # Only item 2 should get deleted

    my $save-to = mktemp();

    my $sub-folder = $save-to.IO.child('deleteme-subfolder');
    mkdirs($sub-folder);

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $save-to.IO.child('base-delete.me');
    my $sub-folder-file = $sub-folder.IO.child('sub-delete.me');
    @delete-us.append($save-to-file) if open($save-to-file, :w).close;
    open($sub-folder-file, :w).close;

    ok $save-to.IO.d, "Folder available to delete";

    my @ls      = ls($save-to, :d, :f);
    my @deleted = rm($save-to, :d, :f);

    my $to-be-deleted = any($save-to-file);
    my $not-deleted   = any($save-to, $sub-folder, $sub-folder-file);

    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(@ls),       "File was found in .ls";
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.IO.path}";
        isnt $path-to-delete, $not-deleted, 'Did not delete sub-file or delete non-empty directory';
    }

    # deletion doesn't always happen immediately
    #is $save-to.IO.e, False, "Folder deleted"; 
}, ".ls and .rm :d :f (no recursion)";


# :d :r
subtest {
    my @delete-us;

    # 1. Folder: /{temp folder}
    # 2. File:   /{temp folder}/base-delete.me 
    # 3. Folder: /{temp folder}/deleteme-subfolder
    # 4. File:   /{temp folder}/deleteme-subfolder/base-delete.me
    # 5. Folder  /{temp folder}/empty-subfolder
    # Only item 5 will be deleted

    my $save-to = mktemp().IO;

    my $sub-folder = $save-to.IO.child('deleteme-subfolder');
    mkdirs($sub-folder);
    my $sub-folder-empty = $save-to.IO.child('empty-subfolder');
    @delete-us.append($sub-folder-empty);
    mkdirs($sub-folder-empty);

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $save-to.IO.child('base-delete.me');
    my $sub-folder-file = $sub-folder.IO.child('sub-delete.me');
    open($save-to-file, :w);
    open($sub-folder-file, :w);

    ok $save-to.IO.d, "Folder available to delete";

    my @ls      = ls($save-to, :d, :r);
    my @deleted = rm($save-to, :d, :r);

    my $to-be-deleted = any($sub-folder-empty);
    my $not-deleted   = any($save-to, $save-to-file, $sub-folder, $sub-folder-file);
    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(@ls),       "File was found in .ls";
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.IO.path}";
        isnt $path-to-delete, $not-deleted, 'Did not delete sub-file or delete non-empty directory';
    }

    # deletion doesn't always happen immediately
    #is $save-to.IO.e, False, "Folder deleted"; 
}, ".ls and .rm :d :r";


# :f :r
subtest {
    my @delete-us;

    # 1. Folder: /{temp folder}
    # 2. File:   /{temp folder}/base-delete.me 
    # 3. Folder: /{temp folder}/deleteme-subfolder
    # 4. File:   /{temp folder}/deleteme-subfolder/base-delete.me
    # 5. Folder  /{temp folder}/empty-subfolder
    # Delete items 2 and 4

    my $save-to = mktemp();

    my $sub-folder = $save-to.IO.child('deleteme-subfolder').IO;
    mkdirs($sub-folder);
    my $sub-folder-empty = $save-to.IO.child('empty-subfolder').IO;
    mkdirs($sub-folder-empty);

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $save-to.IO.child('base-delete.me').IO;
    my $sub-folder-file = $sub-folder.IO.child('sub-delete.me').IO;
    @delete-us.append($save-to-file) if open($save-to-file.IO.path, :w);
    @delete-us.append($sub-folder-file) if open($sub-folder-file.IO.path, :w);

    ok $save-to.IO.d, "Folder available to delete";

    my @ls      = ls($save-to, :f, :r);
    my @deleted = rm($save-to, :f, :r);

    my $to-be-deleted = any($save-to-file, $sub-folder-file);
    my $not-deleted   = any($save-to, $sub-folder, $sub-folder-empty);
    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(@ls),       "File was found in .ls";
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.IO.path}";
        isnt $path-to-delete, $not-deleted, 'Did not delete sub-file or delete non-empty directory';
    }

    # deletion doesn't always happen immediately
    # is $save-to.IO.e, False, "Folder deleted"; 
}, ".ls and .rm :f :r";
