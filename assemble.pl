use strict;

my %hash = (
'VADD' => '0000',
'VDOT' => '0001',
'SMUL' => '0010',
'SST' => '0011',
'VLD' => '0100',
'VST' => '0101',
'SLL' => '0110',
'SLH' => '0111',
'J' => '1000',
'NOOP' => '1111',
'vadd' => '0000',
'vdot' => '0001',
'smul' => '0010',
'sst' => '0011',
'vld' => '0100',
'vst' => '0101',
'sll' => '0110',
'slh' => '0111',
'j' => '1000',
'noop' => '1111',


'0' => '000',
'1' => '001',
'2' => '010',
'3' => '011',
'4' => '100',
'5' => '101',
'6' => '110',
'7' => '111',



);


while(<>){
	if($_ =~ m/^$/){
	}
	elsif($_ =~ m/@/){
		print $_;
	}
	elsif($_ =~ m/#/){
		$_ =~ s/#//;
		print $_;
	}
	else{
		my @tokins = split(/\s+/, $_);
		my $line = "";
		my $cur_tok = 0;
		my $first_tok = $tokins[0];
		foreach my $tokin(@tokins) {
			if($first_tok eq 'vld' && $cur_tok == 3 ){
				$tokin = sprintf("%b", $tokin);
				$tokin = ("0" x (6 - length($tokin))).$tokin;
			}
			elsif($first_tok eq 'vst' && $cur_tok == 3){
				$tokin = sprintf("%b", $tokin);
				$tokin = ("0" x (6 - length($tokin))).$tokin;
			}
			elsif($first_tok eq 'sll' && $cur_tok == 2){
				$tokin = sprintf("%b", $tokin);
				$tokin = ("0" x (9 - length($tokin))).$tokin;
			}
			elsif($first_tok eq 'slh' && $cur_tok == 2){
				$tokin = sprintf("%b", $tokin);
				$tokin = ("0" x (9 - length($tokin))).$tokin;
				#printf("%b\n", $tokin);
			}
			elsif($first_tok eq 'sst' && $cur_tok == 3){
				$tokin = sprintf("%b", $tokin);
				$tokin = ("0" x (6 - length($tokin))).$tokin;
			}
			elsif($first_tok eq 'j' && $cur_tok == 1){
				$tokin = sprintf("%b", $tokin);
				$tokin = ("0" x (12 - length($tokin))).$tokin;
			}

			else {
				$tokin = $hash{$tokin};
			}
			$line = $line.$tokin;
#			print "$tokin => $hash{$tokin}\n";
			$cur_tok++;
		}
		$line = $line.("0" x (16 - length($line)))."\n";
		print $line;
#		print "PING!\n";
	}

}
print "\n";
