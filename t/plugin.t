# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More;

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

  $stash->{_config}->{'Plugin|strung'} = 'higher';
  is_deeply($stash->get_stashed_config($plug), {strung => 'higher'}, 'get_stashed_config');

  $stash->merge_stashed_config($plug);
  is_deeply(attr_hash($plug), {arr => ['empty array?'], strung => 'higher', not => 'not'}, 'merge_stashed_config');

  @{$stash->{_config}}{qw(Plugin|strung Plugin-arr)} = qw(highest matey);
  is_deeply($stash->get_stashed_config($plug), {strung => 'highest', arr => 'matey'}, 'get_stashed_config');

  $stash->merge_stashed_config($plug);
  is_deeply(attr_hash($plug), {arr => ['empty array?', 'matey'], strung => 'highest', not => 'not'}, 'merge_stashed_config');

  # no change
  $stash->merge_stashed_config($plug, {stashed => {}});
  is_deeply(attr_hash($plug), {arr => ['empty array?', 'matey'], strung => 'highest', not => 'not'}, 'merge_stashed_config with stashed');

  $stash->merge_stashed_config($plug, {stashed => {arr => 'ahoy'}});
  is_deeply(attr_hash($plug), {arr => ['empty array?', 'matey', 'ahoy'], strung => 'highest', not => 'not'}, 'merge_stashed_config with stashed');

  $stash->merge_stashed_config($plug, {stashed => {strung => 'up'}});
  is_deeply(attr_hash($plug), {arr => ['empty array?', 'matey', 'ahoy'], strung => 'up', not => 'not'}, 'merge_stashed_config with stashed');

  $stash->merge_stashed_config($plug);
  is_deeply(attr_hash($plug), {arr => ['empty array?', 'matey', 'ahoy', 'matey'], strung => 'highest', not => 'not'}, 'merge_stashed_config with stashed');


}

done_testing;
