# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Zilla::Role::Stash::Plugins;
# ABSTRACT: A Stash that stores arguments for plugins

use Config::MVP::Slicer ();
use Moose::Role;
with qw(
  Dist::Zilla::Role::DynamicConfig
  Dist::Zilla::Role::Stash
);

# we could define a 'plugged' module attribute and create a generic
# method like sub expand_package { $_[0]->plugged_module->expand_package($_[1]) }
# but this is a Role (not an actual stash) and is that really useful?

requires 'expand_package';

=attr argument_separator

A regular expression that will capture
the package name in C<$1> and
the attribute name in C<$2>.

Defaults to C<< ^(.+?)\W+(\w+)$ >>
which means the package variable and the attribute
will be separated by non-word characters
(which assumes the attributes will be
only word characters/valid perl identifiers).

You will need to set this attribute in your stash
if you need to assign to an attribute in a package that contains
non-word characters.
This is an example (taken from the tests in F<t/ini-sep>).

  # dist.ini
  [%Example]
  argument_separator = ^([^|]+)\|([^|]+)$
  -PlugName|Attr::Name = oops
  +Mod::Name|!goo-ber = nuts

=cut

has argument_separator => (
  is       => 'ro',
  isa      => 'Str',
  # "Module::Name:variable" "-Plugin/variable"
  default  => '^(.+?)\W+(\w+)$'
);

=attr _config

Contains the dynamic options.

Inherited from L<Dist::Zilla::Role::DynamicConfig>.

Rather than accessing this directly,
consider L</get_stashed_config> or L</merge_stashed_config>.

=cut

# _config inherited

=attr slicer

Instance of C<Config::MVP::Slicer>
which handles plugin configuration extraction.

=cut

has slicer => (
  is       => 'ro',
  isa      => 'Config::MVP::Slicer',
  default  => sub {
    my $self = shift;
    Config::MVP::Slicer->new({
      config        => $self->_config,
      separator     => $self->argument_separator,
      match_package => sub { $self->expand_package($_[0]) eq $_[1] },
    })
  },
);

=method get_stashed_config

Return a hashref of the config arguments for the plugin.
This is a thin wrapper around L<Config::MVP::Slicer/slice>.

  # with a stash of:
  # _config => {
  #   'APlug.attr1'   => 'value1',
  #   'APlug.second'  => '2nd',
  #   'OtherPlug.attr => '0'
  # }

  # from inside Dist::Zilla::Plugin::APlug

  if( my $stash = $self->zilla->stash_named('%Example') ){
    my $stashed = $stash->get_stashed_config($self);
  }

  # $stashed => {
  #   'attr1'   => 'value1',
  #   'second'  => '2nd'
  # }

=cut

sub get_stashed_config {
  my ($self, $plugin) = @_;

  # TODO: should we compare liberal argument_separator to strict one and warn if not matched?

  return $self->slicer->slice($plugin);
}

=method merge_stashed_config

  $stash->merge_stashed_config($plugin, \%opts);

Get the stashed config (see L</get_stashed_config>),
then attempt to merge it into the plugin.

This require the plugin's attributes to be writable (C<'rw'>).

This is a thin wrapper around L<Config::MVP::Slicer/merge>.

Possible options:

=for :list
* I<stashed>
A hashref like that returned from L</get_stashed_config>.
If not present, L</get_stashed_config> will be called.

=cut

sub merge_stashed_config {
  my ($self, $plugin, $opts) = @_;
  $opts ||= {};
  $opts->{stashed} ||= $self->get_stashed_config($plugin);
  $opts->{slice} = delete $opts->{stashed};
  return $self->slicer->merge($plugin, $opts);
}

=method separate_local_config

Removes any hash keys that are only word characters
(valid perl identifiers (including L</argument_separator>))
because the dynamic keys intended for other plugins will all
contain non-word characters.

Overwrite this if necessary.

=cut

sub separate_local_config {
  my ($self, $config) = @_;
  # keys for other plugins should include non-word characters
  # (like "-Plugin::Name:variable"), so any keys that are only
  # word characters (valid identifiers) are for this object.
  my @local = grep { /^\w+$/ } keys %$config;
  my %other;
  @other{@local} = delete @$config{@local}
    if @local;

  return \%other;
}

no Moose::Role;
1;

=for :stopwords dist-zilla zilla

=for test_synopsis
sub with;

=head1 SYNOPSIS

  # in Dist::Zilla::Stash::MyStash

  with 'Dist::Zilla::Role::Stash::Plugins';

=head1 DESCRIPTION

This is a role for a L<Stash|Dist::Zilla::Role::Stash>
that stores arguments for other plugins.

Stashes performing this role must define I<expand_package>.

=head1 SEE ALSO

=for :list
* L<Config::MVP::Slicer>

=cut
