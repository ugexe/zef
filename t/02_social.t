use v6;
BEGIN { @*INC.push('lib'); };
use Zef;
use Test;
plan 6;

# this file is the toilet in this metaphor

my $meta = Zef.social_meta('Zef'); 														# Get initial meta info
ok $meta.likes >= 0, 'Make sure $meta returned something'; 								# duh

my $user_req = Zef.login( 'zef50000' , 'peterpan' , False );							# Login for liking/commenting later

# LIKES
{
	ok $user_req.social('Zef').like.social_meta.likes == $meta.likes + 1, 'LIKE';		# like the module, see if the returned meta file likes increment
	ok $user_req.social('Zef').like.social_meta.likes == $meta.likes + 1, 'double LIKE';# same as above, make sure value doesnt increment a second time
	ok $user_req.social('Zef').like.social_meta.unlike == $meta.likes, 'un-LIKE';		# ...
	ok $user_req.social('Zef').like.social_meta.unlike == $meta.likes, 'double un-LIKE';# ...
}

# COMMENTS
{
	ok $user_req.social('Zef').comment('This module is literal trash for idiots').social_meta.comments[-1] eq 'This module is literal trash for idiots', 'Trolling like a pro! (comments)';
	ok $user_req.social('Zef').social_meta.comments[-1].delete == 1, 'Oh no its the next morning and you arent drunk! (remove comment);
}
