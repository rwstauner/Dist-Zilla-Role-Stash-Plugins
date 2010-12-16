use strict;
use warnings;
use Test::More;
use Test::MockObject::Extends;

use Dist::Zilla::Tester;
use lib 't/lib';

my $dir = 't/ini-test';

sub attr_hash {
	my ($self) = @_;
	return +{ map { $_ => $self->$_ } qw(arr not strung) };
}

{

	my $zilla = Dist::Zilla::Tester->from_config(
		{ dist_root => $dir },
		{}
	);

	$zilla->build;

	my $stash = $zilla->stash_named('%Test');
	isa_ok($stash, 'Dist::Zilla::Stash::Test');
	my $plug = $zilla->plugin_named('=Test::Plugin');
	isa_ok($plug, 'Test::Plugin');

	my $mock = Test::MockObject::Extends->new( $stash );

	$mock->mock('_config' => sub { {'Plugin|strung' => 'higher'} });
	is_deeply($stash->get_stashed_config($plug), {strung => 'higher'}, 'get_stashed_config');

	$stash->merge_stashed_config($plug);
	is_deeply(attr_hash($plug), {arr => ['empty array?'], strung => 'higher', not => 'not'}, 'merge_stashed_config');

	$mock->mock('_config' => sub { {'Plugin|strung' => 'highest', 'Plugin-arr' => 'matey'} });
	is_deeply($stash->get_stashed_config($plug), {strung => 'highest', arr => 'matey'}, 'get_stashed_config');

	$stash->merge_stashed_config($plug);
	is_deeply(attr_hash($plug), {arr => ['empty array?', 'matey'], strung => 'higher highest', not => 'not'}, 'merge_stashed_config');
	# no change
	$stash->merge_stashed_config($plug, {stashed => {}});
	is_deeply(attr_hash($plug), {arr => ['empty array?', 'matey'], strung => 'higher highest', not => 'not'}, 'merge_stashed_config with stashed');

	$stash->merge_stashed_config($plug, {stashed => {arr => 'ahoy'}});
	is_deeply(attr_hash($plug), {arr => ['empty array?', 'matey', 'ahoy'], strung => 'higher highest', not => 'not'}, 'merge_stashed_config with stashed');

	$stash->merge_stashed_config($plug, {stashed => {strung => 'up'}, join => '-'});
	is_deeply(attr_hash($plug), {arr => ['empty array?', 'matey', 'ahoy'], strung => 'higher highest-up', not => 'not'}, 'merge_stashed_config with stashed');

}

done_testing;
