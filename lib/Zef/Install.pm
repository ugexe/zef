class Zef::Install;

# copy module to correct location
# save information to db for fast lookup, fallback to directory search or with flag
# copy scripts in /project/bin to appropriate location

method install(Str :$unit, Str :$auth, Str :$version) {
	return 1;
}

