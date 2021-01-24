use v6;
use Zef::Utils::FileSystem;

use Test;
plan 4;

my $save-to = $*TMPDIR.child(time);
my $dir-id  = 0;

# :d :f :r
subtest "list-paths and delete-paths :d :f :r (rm -rf)" => {
    temp $save-to = $save-to.child(++$dir-id);
    my @delete-us;

    # 1. Folder: /{temp folder}
    # 2. File:   /{temp folder}/base-delete.me 
    # 3. Folder: /{temp folder}/deleteme-subfolder
    # 4. File:   /{temp folder}/deleteme-subfolder/base-delete.me
    # All 4 items should get deleted

    mkdir($_) and @delete-us.append($_) with ~$save-to;
    my $sub-folder = $save-to.child('deleteme-subfolder');
    mkdir($_) and @delete-us.append($_) with ~$sub-folder;

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $save-to.child('base-delete.me');
    my $sub-folder-file = $sub-folder.child('sub-delete.me');
    $save-to-file.spurt(time);
    $sub-folder-file.spurt(time);
    @delete-us.append($save-to-file.path);
    @delete-us.append($sub-folder-file.path);

    ok $save-to.d, "Folder available to delete";

    my @paths   = list-paths($save-to, :f, :d, :r);
    my @deleted = delete-paths($save-to, :f, :d, :r);

    is +@deleted, +@paths + 1;

    my $to-be-deleted = any($save-to, $sub-folder, $save-to-file, $sub-folder-file);
    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(|@paths,$save-to), 'file was found in list-paths';
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.path}";
    }
}


# :d :f
subtest "list-paths and delete-paths :d :f (no recursion)" => {
    temp $save-to = $save-to.child(++$dir-id);

    my @delete-us;

    # 1. Folder: /{temp folder}
    # 2. File:   /{temp folder}/base-delete.me 
    # 3. Folder: /{temp folder}/deleteme-subfolder
    # 4. File:   /{temp folder}/deleteme-subfolder/base-delete.me
    # Only item 2 should get deleted

    my $sub-folder = $save-to.child('deleteme-subfolder');
    mkdir($sub-folder);

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $save-to.child('base-delete.me');
    my $sub-folder-file = $sub-folder.child('sub-delete.me');
    $save-to-file.spurt(time);
    $sub-folder-file.spurt(time);
    @delete-us.append($save-to-file);

    ok $save-to.d, "Folder available to delete";

    my @paths   = list-paths($save-to, :d, :f);
    my @deleted = delete-paths($save-to, :d, :f);

    is +@deleted, +@paths + 1;

    my $to-be-deleted = any($save-to-file);
    my $not-deleted   = any($save-to, $sub-folder, $sub-folder-file);

    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(@paths),       "File was found in list-paths";
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.path}";
        isnt $path-to-delete, $not-deleted, 'Did not delete sub-file or delete non-empty directory';
    }
}


# :d :r
subtest "list-paths and delete-paths :d :r" => {
    temp $save-to = $save-to.child(++$dir-id);

    my @delete-us;

    # 1. Folder: /{temp folder}
    # 2. File:   /{temp folder}/base-delete.me 
    # 3. Folder: /{temp folder}/deleteme-subfolder
    # 4. File:   /{temp folder}/deleteme-subfolder/base-delete.me
    # 5. Folder  /{temp folder}/empty-subfolder
    # Only item 5 will be deleted

    my $sub-folder = $save-to.child('deleteme-subfolder');
    mkdir($sub-folder);
    my $sub-folder-empty = $save-to.child('empty-subfolder');
    @delete-us.append($sub-folder-empty);
    mkdir($sub-folder-empty);

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $save-to.child('base-delete.me');
    my $sub-folder-file = $sub-folder.child('sub-delete.me');
    $save-to-file.spurt(time);
    $sub-folder-file.spurt(time);

    ok $save-to.d, "Folder available to delete";

    my @paths   = list-paths($save-to, :d, :r);
    my @deleted = delete-paths($save-to, :d, :r);

    is +@deleted, +@paths + 1;

    my $to-be-deleted = any($sub-folder-empty);
    my $not-deleted   = any($save-to, $save-to-file, $sub-folder, $sub-folder-file);
    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(@paths),       "File was found in list-paths";
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.path}";
        isnt $path-to-delete, $not-deleted, 'Did not delete sub-file or delete non-empty directory';
    }
}


# :f :r
subtest "list-paths and delete-paths :f :r" => {
    temp $save-to = $save-to.child(++$dir-id);

    my @delete-us;

    # 1. Folder: /{temp folder}
    # 2. File:   /{temp folder}/base-delete.me 
    # 3. Folder: /{temp folder}/deleteme-subfolder
    # 4. File:   /{temp folder}/deleteme-subfolder/base-delete.me
    # 5. Folder  /{temp folder}/empty-subfolder
    # Delete items 2 and 4

    my $sub-folder = $save-to.child('deleteme-subfolder');
    mkdir($sub-folder);
    my $sub-folder-empty = $save-to.child('empty-subfolder');
    mkdir($sub-folder-empty);

    # create 2 test files, one in each directory we created above
    my $save-to-file    = $save-to.child('base-delete.me');
    my $sub-folder-file = $sub-folder.child('sub-delete.me');
    $save-to-file.spurt(time);
    $sub-folder-file.spurt(time);
    @delete-us.append($save-to-file);
    @delete-us.append($sub-folder-file);

    ok $save-to.d, "Folder available to delete";

    my @paths   = list-paths($save-to, :f, :r);
    my @deleted = delete-paths($save-to, :f, :r);

    is +@deleted, +@paths + 3;

    my $to-be-deleted = any($save-to-file, $sub-folder-file);
    my $not-deleted   = any($save-to, $sub-folder, $sub-folder-empty);
    for @delete-us -> $path-to-delete {
        is $path-to-delete, any(@paths),    "File was found in list-paths";
        is $path-to-delete, $to-be-deleted, "Deleted: {$path-to-delete.path}";
        isnt $path-to-delete, $not-deleted, 'Did not delete sub-file or delete non-empty directory';
    }
}

try rmdir($save-to);


done-testing;