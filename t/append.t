# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More;

use Dist::Zilla::Tester;
use lib 't/lib';

my $dir = 't/ini-append';

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

  note explain $stash->_config;
  is_deeply(
    $stash->_config,
    { 'Plugin.arr[0]' => 'stash value' },
    'initial _config correct',
  );

  $stash->_append_mvp_values('Plugin.arr' => [ qw{ one two } ]);
  note explain $stash->_config;
  is_deeply(
    $stash->_config,
    {
      'Plugin.arr[0]' => 'stash value',
      'Plugin.arr[1]' => 'one',
      'Plugin.arr[2]' => 'two',
    },
    'appended _config correct',
  );

  $stash->merge_stashed_config($plug);
  note explain attr_hash($plug);
  is_deeply(
    attr_hash($plug),
    {
      arr    => [ 'local value', 'stash value', 'one', 'two' ],
      strung => q{},
      not    => 'not',
    },
    'merge_stashed_config correct',
  );

}

done_testing;
