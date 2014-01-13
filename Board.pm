package Board;

use strict;
use warnings;
use Block;
use Cell;
use Storable qw(dclone);
use Data::Dumper;

=head1 new

  Constructor for board object.

  Boards consist of 9 block objects, ordered left to right and top to bottom by value 1 - 9.
      1 2 3
      4 5 6
      7 8 9

  Each block consists of 9 cell objects, ordered in the same way inside blocks, as blocks are inside the board.

  A board is initialized by passing in an array ref of board values.

  There is a bit of trickiness in specifying the values for the initial board:
    1. Values are specified block by block, not by row or columns.
    2. Empty cells are specificied with a value of 0 (since this is invalid in sudoku and it is easier to seen that ommiting a value).
    A block of  3 6     would be passed in as 3,6,0,0,0,9,7,4,5,
                    9
                7 4 5

  Example:
  my $board = Board->new([0,1,0,0,0,0,4,6,0,
                          3,6,8,0,1,0,0,7,0,
                          4,0,0,6,0,9,0,5,3,
                          0,4,6,1,0,0,0,2,5,
                          1,5,0,0,2,0,0,8,3,
                          9,3,0,0,0,8,7,1,0,
                          2,8,0,7,0,3,0,0,1,
                          0,9,0,0,4,0,7,3,2,
                          0,7,1,0,0,0,0,4,0,]);

=cut

sub new {
  my ($class, $values) = @_;
  unshift @$values, 'fencepost';
  my $self;

  for my $num (1 .. 9) {
    my $block = Block->new();
    $self->{$num} = $block;
    for (1 .. 9) {
      if (defined $values->[$_] and $values->[$_] > 0) {
        my $cell = $self->{$num}->{$_};
        $cell->set_value($values->[$_]);
      }
    }
    splice @$values, 1, 9;
  }
  return bless $self, $class;
}

=head1 clone

  Simple method to clone our board object.

  Essential in the guessing process.

  my $clone = $board->clone;

=cut

sub clone {
  my $self = shift;
  return dclone($self);
}

=head1 display

  Method to pretty print out board.

  $board->display;

=cut

sub display {
  my $self = shift;
  print "-" x 36 . "\n";
  for my $row (1 .. 9) {
    my $row_values = $self->get_row_values($row);
    $self->print_out($row_values);
    print "-" x 36 . "\n" if ($row == 3 or $row == 6 or $row == 9);
  }
} 

=head1 print_out

  Used by our display method.

  Gets the row values and prints them out.

  $board->print_out($row_values);

=cut 

sub print_out {
  my ($self, $row_values) = @_;
  
  print "|  ";
  for my $num (1 .. 9) {
    print $row_values->{$num} . "  ";
    if ($num % 3 == 0) {
      print "|  ";
    }
  }
  print "\n";
}

=head1 get_row_values

  Helper method for board display.

  my $rows = $board->get_row_values;

=cut

sub get_row_values {
  my ($self, $row) = @_;

  my @blocks;
  if ($row < 4) {
    @blocks = (1 .. 3);
  } elsif ($row < 7) {
    @blocks = (4 .. 6);
  } else {
    @blocks = (7 .. 9);
  }

  my @block_rows;
  if ($row == 1 or $row == 4 or $row == 7) {
    @block_rows = (1 .. 3);
  } elsif ($row == 2 or $row == 5 or $row == 8) {
    @block_rows = (4 .. 6);
  } else {
    @block_rows = (7 .. 9);
  }
  my $row_values;
  my $counter = 1;
  for my $block_num (@blocks) {
    my $block_values = $self->{$block_num}->get_block_values();
    for my $cell_num (@block_rows) {
      $row_values->{$counter} = $block_values->{$cell_num};
      $counter++;
    }
  }
  return $row_values;
}

=head1 shuffle_down_options

  Method that sifts down through our option removal methods,
  and exits when it has run through once without making any changes.

  $board->shuffle_down_options;

=cut

sub shuffle_down_options {
  my $self = shift;
  
  while (1) {
    my $removals = 0;
    $removals += $self->remove_board_column_options();
    $removals += $self->remove_board_row_options();
    $removals += $self->remove_board_block_options();
    if ($removals == 0) {
      return;
    }
  }
}

=head1 solve

  Our main control method.

  Solves as much as it can deterministically, and then
  attempts to guess.

  $board->solve;

=cut

sub solve {
  my $self = shift;

  while (1) {
    $self->deterministic_solve();
    if ($self->is_solved) {
      $self->display;
      exit;
    }

    $self->guess_solve();
    if ($self->is_impossible) {
      die "Something went wrong. Impossible board\n";
    }
    if ($self->is_solved) {
      $self->display;
      exit;
    }
  }
}

=head1 deterministic_solve

  Control method for our 'deterministic' solve methods.
  This is always tried before any guessing.

  $board->deterministic_solve();

=cut

sub deterministic_solve {
  my $self = shift;

  for (1 .. 3) {
    $self->fill_in_options;
    $self->shuffle_down_options;
    $self->fill_only_possible;
    $self->shuffle_down_options;
    $self->disjoint_pair_elimination;
    $self->shuffle_down_options;
    if ($self->is_solved) {
      return;
    }
  }
}

=head1 test_guess

  The meat out the guessing process.

  Creates a clone of our board, and the sets the value for our guess.
  From there it wil try to solve the board deterministically.
  If this fails to solve the board, we will launch into another round of guessing.
  This is depth-first recursion, and possibly a source of our slowness in some guessing cases.

  To invoke, we must pass in block number, cell_number, and the value for the cell.
  If we want to guess a value of 4 in block 1, cell 2:
  
  $board->test_guess(1,2,4);

  This returns a boolean value: 1 for a guess that lead to a solve, 0 for failure.

  if ($board->test_guess(1,2,4) {
    $cell->set_value(4);
  }

=cut

sub test_guess {
  my ($self, $block, $cell_number, $value) = @_;
  return 1 if ($self->is_solved);
  return if ($self->is_impossible);

  my $clone = $self->clone();
  my $cell = $clone->{$block}{$cell_number};
  $cell->set_value($value);
  return if ($clone->is_impossible);
  $clone->display;

  $clone->deterministic_solve;
  if ($clone->is_solved) {
    return 1;
  } 
  return $clone->guess_solve;
}

=head1 test_choices 

  Method that 'tries out' our choices.

  Processes the list of choices given to it from check_for_options.
  In order to make 'guesses' work, we launch a test_guess method, that
  clones our board object and tries to solve with the guessed value.
  If this process succeeds, we return and set the guessed value in
  our real board.

  $board->test_choices($options);

=cut

sub test_choices {
  my ($self, $choices) = @_;
 
  if (defined $choices) {
    for my $block (keys %$choices) {
      for my $cell (keys %{$choices->{$block}}) {
        for my $value (keys %{$choices->{$block}{$cell}}) {
          if ($self->test_guess($block, $cell, $value)) {
            $self->{$block}{$cell}->set_value($value);
            return 1;
          }
        }
      }
    }
  }
}

=head1 guess_solve

  Method that controls our 'guessing' phase.

  Tries to solve the puzzle deterministically first.
  Then will get all possible options, and launches the guessing.

  $board->guess_solve;

=cut
  

sub guess_solve {
  my $self = shift;
  return 1 if ($self->is_solved);
  return if ($self->is_impossible);

  $self->deterministic_solve;

  my $choices;
  for my $i (2) {
    $choices = $self->check_for_options($i);
    if (defined $choices) {
      if ($self->test_choices($choices)) {
        return 1;
      }
    }
  }
}

=head1 check_for_options

  Helper method that will return a hashref laid out as $choices->{block_num}{cell_num}{option_num};

  Pass in the number of options you want a cell to have (i.e. 2);
  Used in our 'guessing' phase. We generally will only guess on cells that have only 2 options left.

  my $choices = $board->check_for_options(2);

=cut

sub check_for_options {
  my ($self, $number) = @_;

  my $choices;

  for (1 .. 9) {
    my $block = $self->{$_};
    for my $i (1 .. 9) {
      my $cell = $block->{$i};
      my $options = $cell->get_options();
      if (scalar keys %$options == $number) {
        for my $value (keys %$options) {
          $choices->{$_}{$i}{$value}++
        }
      }
    }
  }
  return $choices;
}

=head1 is_solved

  Our method that allows us to check if our board is solved.

  if ($board->is_solved) {
    print "WIN\n";
    exit;
  }

=cut

sub is_solved {
  my $self = shift;

  for (1 .. 9) {
    my $column_cells = $self->get_column_cells($_);
    my %check;
    for my $cell (@$column_cells) {
      my $value = $cell->get_value;
      return 0 if (not defined $value);
      return 0 if (exists $check{$value});
      $check{$value}++;
    }
  }

  for (1 .. 9) {
    my $row_values = $self->get_row_values($_);
    my %check;
    for my $value (keys %$row_values) {
      return 0 if (not defined $value);
      return 0 if (exists $check{$value});
      $check{$value}++;
    }
  }

  for (1 .. 9) {
    my $block = $self->{$_};
    my %check;
    for my $i (keys %$block) {
      my $cell = $block->{$i};
      my $value = $cell->get_value;
      return 0 if (not defined $value);
      return 0 if (exists $check{$value});
      $check{$value}++;
    }
  }
  return 1;
}

=head1 is_impossible

  Method that tests if a board is in an impossible configuration.
  This does three checks:
    1. If two cells in the same row, column, or block, each have only one option
       and the option is the same the board is impossible.
    2. If a cell has only one option and some other cell in the row, column, or block
       already has that value the board is impossible.
    3. If a cell has no value and no options the board is impossible.

  die "Uh oh!\n" if ($board->is_impossible);

=cut

sub is_impossible {
  my $self = shift;

  for (1 .. 9) {
    my $column_cells = $self->get_column_cells($_);
    my %one_options;
    my %column_values;
    for my $cell (@$column_cells) {
      my $value = $cell->get_value;
      my $options = $cell->get_options;
      next if (not defined $value);
      if (exists $column_values{$value}) {
        return 1;
      } else {
        $column_values{$value}++;
      }
      if (scalar keys %$options == 1) {
        my $option;
        for my $i (keys %$options) {
          $option = $i;
        }
        if (exists $one_options{$option}) {
          return 1;
        } elsif (exists $column_values{$option}) {
          return 1;
        } else {
          $one_options{$option}++;
        }
      }
      if (not defined $value and (scalar keys %$options == 0)) {
        return 1;
      }
    }
  }

  for (1 .. 9) {
    my $row_cells = $self->get_row_cells($_);
    my %one_options;
    my %row_values;
    for my $cell (@$row_cells) {
      my $value = $cell->get_value;
      my $options = $cell->get_options;
      next if (not defined $value);
      if (exists $row_values{$value}) {
        return 1;
      } else {
        $row_values{$value}++;
      }
      if (scalar keys %$options == 1) {
        my $option;
        for my $i (keys %$options) {
          $option = $i;
        }
        if (exists $one_options{$option}) {
          return 1;
        } elsif (exists $row_values{$option}) {
          return 1;
        } else {
          $one_options{$option}++;
        }
      }
      if (not defined $value and (scalar keys %$options == 0)) {
        return 1;
      }
    }
  }

  for (1 .. 9) {
    my $block = $self->{$_};
    my %block_values;
    my %one_options;
    for my $i (keys %$block) {
      my $cell = $block->{$i};
      my $value = $cell->get_value;
      my $options = $cell->get_options;
      next if (not defined $value);
      if (exists $block_values{$value}) {
        return 1;
      } else {
        $block_values{$value}++;
      }
      if (scalar keys %$options == 1) {
        my $option;
        for my $i (keys %$options) {
          $option = $i;
        }
        if (exists $one_options{$option}) {
          return 1;
        } elsif (exists $block_values{$option}) {
          return 1;
        } else {
          $one_options{$option}++;
        }
      }
      if (not defined $value and (scalar keys %$options == 0)) {
        return 1;
      }
    }
  }
  return 0;
}

=head1 remove_board_block_options

  Method that goes block by block, and removes from options from cells without values, based
  on the values set on other cells in the block.

  $board->remove_board_block_options;

  This method is usually called in conjunction with remove_board_row_options
  and remove_board_column_options.

=cut

sub remove_board_block_options {
  my $self = shift;
  my $removals = 0;

  for (1 .. 9) {
    my $block = $self->{$_};
    $removals += $block->remove_options_by_block();
  }
  return $removals;
}

=head1 remove_board_row_options

  Method that will go row by row and remove an option from a cell,
  if another cell in the row has that value.

  Called in void context:
  $board->remove_board_row_options;

  You can also receive the number of removals back.
  This way, we can loop over this method until we are know we are no longer removing anything.

  my $removals = $board->remove_board_row_options;

=cut

sub remove_board_row_options {
  my $self = shift;
  my $removals = 0;

  for my $row (1 .. 9) {
    my @blocks;
    if ($row < 4) {
      @blocks = (1 .. 3);
    } elsif ($row < 7) {
      @blocks = (4 .. 6);
    } else {
      @blocks = (7 .. 9);
    }
  
    my @block_rows;
    if ($row == 1 or $row == 4 or $row == 7) {
      @block_rows = (1 .. 3);
    } elsif ($row == 2 or $row == 5 or $row == 8) {
      @block_rows = (4 .. 6);
    } else {
      @block_rows = (7 .. 9);
    }
  
    my @cells;
  
    for my $i (@blocks) {
      my $block = $self->{$i};
      for my $n (@block_rows){
        my $cell = $block->{$n};
        push @cells, $cell;
      }
    }
  
    for my $cell (@cells) {
      if (defined $cell->get_value()) {
        my $value = $cell->get_value();
        for (@cells) {
          next if ($cell == $_);
          next if (defined $_->get_value());
          my $options = $_->get_options;
          if (defined $options->{$value}) {
            $_->remove_option($value);
            $removals++;
          }
        }
      }
    }
  }
  return $removals;
}

=head1 remove_board_column_options

  Method that will go column by column and remove an option from a cell,
  if another cell in the column has that value.

  Called in void context:
  $board->remove_board_column_options;

  You can also receive the number of removals back.
  This way, we can loop over this method until we are know we are no longer removing anything.

  my $removals = $board->remove_board_column_options;

=cut
  

sub remove_board_column_options {
  my $self = shift;
  my $removals = 0;

  for my $column (1 .. 9) {
    my $cells = $self->get_column_cells($column);

    for my $cell (@$cells) {
      if (defined $cell->get_value()) {
        my $value = $cell->get_value();
        for (@$cells) {
          next if ($cell == $_);
          next if (defined $_->get_value());
          my $options = $_->get_options;
          if (defined $options->{$value}) {
            $_->remove_option($value);
            $removals++;
          }
        }
      }
    }
  }
  return $removals;
} 

=head1 get_column_cells

  Returns the cells, unordered, for a given column

  my $column_cells = $board->get_column_cells(1);

=cut

sub get_column_cells {
  my ($self, $column) = @_;

  my @blocks;
  if ($column < 4) {
    @blocks = qw(1 4 7);
  } elsif ($column < 7) {
    @blocks = qw(2 5 8);
  } else {
    @blocks = qw(3 6 9);
  }

  my @cells;
  if ($column == 1 or $column == 4 or $column == 7) {
    @cells = qw(1 4 7);
  } elsif ($column == 2 or $column == 5 or $column == 8) {
    @cells = qw(2 5 8);
  } else {
    @cells = qw(3 6 9);
  }

  my $return;

  for my $i (@blocks) {
    my $block = $self->{$i};
    for my $n (@cells) {
      push @$return, $block->{$n};
    }
  }
  return $return;
}

=head1 get_row_cells

  Returns all of the cells, unordered, for a given row number;

  my $row_cells = $board->get_row_cells(3);

=cut

sub get_row_cells {
  my ($self, $row) = @_;

  my @blocks;
  if ($row < 4) {
    @blocks = qw(1 2 3);
  } elsif ($row < 7) {
    @blocks = qw(4 5 6);
  } else {
    @blocks = qw(7 8 9);
  }

  my @cells;
  if ($row == 1 or $row == 4 or $row == 7) {
    @cells = qw(1 2 3);
  } elsif ($row == 2 or $row == 5 or $row == 8) {
    @cells = qw(4 5 6);
  } else {
    @cells = qw(7 8 9);
  }

  my $return;

  for my $i (@blocks) {
    my $block = $self->{$i};
    for my $n (@cells) {
      push @$return, $block->{$n};
    }
  }
  return $return;
}

=head1 fill_in_options

  Method that goes through each block (since these are the easiest to iterate over 
  in our model) and if a cell has no value, and only one option, the cell must
  have the option value.

  One of our more frequently called solve routines.

  $board->fill_in_options;

=cut

sub fill_in_options {
  my $self = shift;
  
  while (1) {
    my $changes = 0;
    for my $i (1 .. 9) {
      my $block = $self->{$i};
      for my $n (1 .. 9) {
        my $cell = $block->{$n};
        my $options = $cell->get_options();
        if (scalar keys %$options == 1) {
          my $value;
          for (keys %$options) {
            $value = $_;
          }
          $cell->set_value($value);
          $self->deterministic_solve;
          $changes++;
        }
      }
    }
    return if ($changes == 0);
  }
}

=head1 disjoing_pair_elimination

  Complicated, gigantic method that may not even work currently.

  The idea is this: Go by row, column, and cell.
  If two cells share a pair of options (ex 2 and 6) and no other cell
  contains either of those options, the only options avaible for our first two
  cells are, in our example, 2 or 6.

  EX: If two cells have the options 2,3,4,7 and 3,5,7,9 our possible pair is 3,7.
      If no other cells contain a 2 or 7, the we can reduce those cells to 3,7 and 3,7.

  $board->disjoint_pair_elimination;

=cut

sub disjoint_pair_elimination {
  my $self = shift;

  for my $type ('column', 'row', 'block') {
   for (1 .. 9) {
     my $pairs;
     my $pair_blacklist;
     my $numbers_in_pairs;
     my $cells;
     if ($type eq 'column') {
       $cells = $self->get_column_cells($_);
     } elsif ($type eq 'row') {
       $cells = $self->get_row_cells($_);
     } elsif ($type eq 'block') {
       my $block = $self->{$_};
       for my $cell_num (1 .. 9) {
         push @$cells, $block->get_cell($cell_num);
       }
     }
     for my $cell (@$cells) {
       my $options = $cell->get_options;
       next if (not defined $options);
       for my $option_1 (keys %$options) {
         next if (exists $pair_blacklist->{$option_1});
         for my $option_2 (keys %$options) {
           next if (exists $pair_blacklist->{$option_2});
           next if ($option_2 == $option_1);
           my $pair_key;
           if ($option_1 < $option_2) {
             $pair_key = "$option_1-$option_2";
           } else {
             $pair_key = "$option_2-$option_1";
           }
           if (exists $numbers_in_pairs->{$option_1}) {
             for my $key (keys %$pairs) {
               my $pair = $pairs->{$key}{pair};
               for my $number (@$pair) {
                 if ($number == $option_1) {
                   $pairs->{$pair_key} = {};
                   $pair_blacklist->{$number}++;
                 }   
               }   
             }
             next;   
           }
 
           if (exists $numbers_in_pairs->{$option_2}) {
             for my $key (keys %$pairs) {
               my $pair = $pairs->{$key}{pair};
               for my $number (@$pair) {
                 if ($number == $option_2) {
                   $pairs->{$pair_key} = {};
                   $pair_blacklist->{$number}++;
                 }   
               }   
             }
             next;   
           }   
 
           if (not defined $pairs->{$pair_key}) {
             $pairs->{$pair_key}{cell_1} = $cell;
             $pairs->{$pair_key}{pair} = [$option_1,$option_2];
           } elsif (defined $pairs->{$pair_key}{cell_1} and (not defined $pairs->{$pair_key}{cell_2})) {
             $numbers_in_pairs->{$option_1}++;
             $numbers_in_pairs->{$option_2}++;
             next if ($pairs->{$pair_key}{cell_1} == $cell);
             $pairs->{$pair_key}{cell_2} = $cell;
           } else {
             $pairs->{$pair_key} = {};
             $pair_blacklist->{$option_1}++;
             $pair_blacklist->{$option_2}++;
           }  
         }
       }
     }
     for my $pair (keys %$pairs) {
       next unless (defined $pairs->{$pair}{cell_1} and defined $pairs->{$pair}{cell_2});
       my $numbers = $pair->{$pair}{pair};
       my $number_1 = $numbers->[0];
       my $number_2 = $numbers->[1];
       my $cell_1 = $pair->{$pair}{cell_1};
       my $cell_2 = $pair->{$pair}{cell_2};
       my $cells = [$cell_1, $cell_2];
 
       for my $cell (@$cells) {
         my $options = $cell->get_options;
         for my $option (keys %$options) {
           if (($option != $number_1) and ($option != $number_2)) {
             $cell->remove_option($option);
           }
         }
       }
     }
   }
  }
}

=head1 fill_only_possible

  A method that will go through by row, by column, and by block.

  In any of these items, if there is only ONE cell with a possible value,
  that cell must have that value.
  
  Called frequently in conjunction with fill_in_options.

  $board->fill_only_possible();

=cut

sub fill_only_possible {
  my $self = shift;

  while (1) {
    my $changes = 0;
    $self->shuffle_down_options;
    for (1 .. 9) {
      my $column_option;
      my $column_blacklist;
      my $column_cells = $self->get_column_cells($_);
      for my $cell (@$column_cells) {
        my $options = $cell->get_options;
        for my $option (keys %$options) {
          next if (exists $column_blacklist->{$option});
          if (exists $column_option->{$option}) {
            delete $column_option->{$option};
            $column_blacklist->{$option} = 1;
          } else {
            $column_option->{$option} = $cell;
          }
        }
      }
  
      if (defined $column_option) {
        for my $value (keys %$column_option) {
          my $cell = $column_option->{$value};
          $cell->set_value($value);
          $changes++;
        }
      }
    }
  
    $self->shuffle_down_options;
    for (1 .. 9) {
      my $block_option;
      my $block_blacklist;
      my $block = $self->{$_};
      for my $i (keys %$block) {
        my $cell = $block->{$i};
        my $options = $cell->get_options;
        for my $option (keys %$options) {
          next if (exists $block_blacklist->{$option});
          if (exists $block_option->{$option}) {
            delete $block_option->{$option};
            $block_blacklist->{$option} = 1;
          } else {
            $block_option->{$option} = $cell;
          }
        }
      }
      if (defined $block_option) {
        for my $value (keys %$block_option) {
          my $cell = $block_option->{$value};
          $cell->set_value($value);
          $changes++;
        }
      }
    } 
  
    $self->shuffle_down_options;
    for (1 .. 9) {
      my $row_option;
      my $row_blacklist;
      my $row_cells = $self->get_row_cells($_);
      for my $cell (@$row_cells) {
        my $options = $cell->get_options;
        for my $option (keys %$options) {
          next if (exists $row_blacklist->{$option});
          if (exists $row_option->{$option}) {
            delete $row_option->{$option};
            $row_blacklist->{$option} = 1;
          } else {
            $row_option->{$option} = $cell;
          }
        }
      }
  
      if (defined $row_option) {
        for my $value (keys %$row_option) {
          my $cell = $row_option->{$value};
          $cell->set_value($value);
          $changes++;
        }
      }
    }
    return if ($changes == 0);
  }
}

1;

