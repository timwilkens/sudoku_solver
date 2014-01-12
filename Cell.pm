package Cell;

use strict;
use warnings;

=head1 new
  
  Constructor for our most basic object, the cell.

  A cell has ONE of two things:
    1. A value. The cell has been set (either from the start or through game play).
    2. A hash of possible values. These are the values that are legal to play for that cell.
       Options are eliminated as play goes on.

  Initialized with no value passed in, cell createdw with no value and has ALL numbers set as possible options.
  my $cell = Cell->new;

  Passed in with value, sets the cell value and doesn't create an options hash.
  my $cell = Cell->new(4);

=cut

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

=head1 get_value

  Returns our cell value;
  
  my $value = $cell->get_value;

=cut

sub get_value {
  my $self = shift;
  return $self->{value};
}

=head1 set_value

  Sets our cell value, and empties our options hash.

  $cell->set_value(5);

=cut

sub set_value {
  my ($self, $value) = @_;

  $self->{value} = $value;
  $self->{options} = {};

  return $self;
}

=head1 remove_option

  Removes an option value for a specific cell.

  $cell->remove_option(3);

=cut

sub remove_option {
  my ($self, $option) = @_;

  delete $self->{options}{$option};
}

=head1 get_options
  
  Returns the options hashref for a given cell.

  my $options = $cell->get_options;

=cut

sub get_options {
  my $self = shift;
  return $self->{options};
}

1;

