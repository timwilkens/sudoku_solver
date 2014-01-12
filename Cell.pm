package Cell;

use strict;
use warnings;

sub new {
  my ($class, $value) = @_;

  my $self;
  if (defined $value) {
 
    $self->{value} = $value;
    return bless $self, $class;
  } else {

    for my $num (1 .. 9) {
      $self->{options}{$num} = 1;
    }
    return bless $self, $class;
  }
}

sub get_value {
  my $self = shift;
  return $self->{value};
}

sub set_value {
  my ($self, $value) = @_;

  $self->{value} = $value;
  $self->{options} = {};

  return $self;
}

sub remove_option {
  my ($self, $option) = @_;

  delete $self->{options}{$option};
}

sub get_options {
  my $self = shift;
  return $self->{options};
}

1;

