use v6;
END { exit 0 }
try require Zef::Manifest;

# Workaround 0.IO related bugs in GLR till next nom merge.
# Otherwise Zef is likely to be one of the first modules installed, 
# and bin/zef will end up as file 0 (which .files fails on)

my @curlis = [CompUnitRepo::Local::Installation.new(%*CUSTOM_LIB<site>),];

for @curlis -> $cur {
    with ::('Zef::Manifest').new(:$cur, :create) -> $manifester {
        with $manifester.read.hash -> %manifest is copy {
            unless ?%manifest<file-count> {
                %manifest<file-count> = 1;
                try { mkdir(~$cur) unless $cur.IO.e }
                try $manifester.write(|%manifest<dists>, :file-count(1));
            }
        }
    }
}

exit 0;