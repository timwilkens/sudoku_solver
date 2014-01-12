package Board;

use strict;
use warnings;
use Block;
use Cell;
use Storable qw(dclone);
use Data::Dumper;

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

sub clone {
  my $self = shift;
  return dclone($self);
}

sub display {
  my $self = shift;
  print "-" x 36 . "\n";
  for my $row (1 .. 9) {
    my $row_values = $self->get_row_values($row);
    $self->print_out($row_values);
    print "-" x 36 . "\n" if ($row == 3 or $row == 6 or $row == 9);
  }
}  

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

sub deterministic_solve {
  my $self = shift;

  for (1 .. 5) {
    $self->fill_in_options;
    $self->shuffle_down_options;
    $self->fill_only_possible;
    $self->shuffle_down_options;
    if ($self->is_solved) {
      return;
    }
  }
}

sub test_guess {
  my ($self, $block, $cell_number, $value) = @_;
  return 1 if ($self->is_solved);
  return if ($self->is_impossible);

  my $clone = $self->clone();
  my $cell = $clone->{$block}{$cell_number};
  $cell->set_value($value);
  $clone->display;
  if ($clone->is_impossible) {
    return;
  }
  $clone->deterministic_solve;
  if ($clone->is_solved) {
    return 1;
  } 
  return $clone->guess_solve;
}

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
 for my $i (3) {
    $choices = $self->check_for_options($i);
    if (defined $choices) {
      if ($self->test_choices($choices)) {
        return 1;
      }
    }
  } 
}

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

sub is_impossible {
  my $self = shift;

  for (1 .. 9) {
    my $column_cells = $self->get_column_cells($_);
    my %check;
    for my $cell (@$column_cells) {
      my $value = $cell->get_value;
      next if (not defined $value);
      if (exists $check{$value}) {
        return 1;
      }
      $check{$value}++;
    }
  }

  for (1 .. 9) {
    my $row_values = $self->get_row_values($_);
    my %check;
    for my $value (keys %$row_values) {
      next if (not defined $value);
      if (exists $check{$value}) {
        return 1;
      }
      $check{$value}++;
    }
  }

  for (1 .. 9) {
    my $block = $self->{$_};
    my %check;
    for my $i (keys %$block) {
      my $cell = $block->{$i};
      my $value = $cell->get_value;
      next if (not defined $value);
      if (exists $check{$value}) {
        return 1;
      }
      $check{$value}++;
    }
  }
  return 0;
}

sub remove_board_block_options {
  my $self = shift;
  my $removals = 0;

  for (1 .. 9) {
    my $block = $self->{$_};
    $removals += $block->remove_options_by_block();
  }
  return $removals;
}

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

sub fill_in_options {
  my $self = shift;

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
        $self->shuffle_down_options;
      }
    }
  }
}

sub fill_only_possible {
  my $self = shift;

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
        $self->shuffle_down_options;
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
        $self->shuffle_down_options;
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
        $self->shuffle_down_options;
      }
    }
  }
}

1;

