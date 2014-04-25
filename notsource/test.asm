@0
j 5	// To j -2
noop
noop
j 3	// To slh 0 1
noop
j -2	// To j 3

slh 0 1		// Test loading high bytes into each register
slh 1 2
slh 2 3
slh 3 4
slh 4 5
slh 5 6
slh 6 7
slh 7 8

sst 0 0 0	// Test scalar store
sst 1 1 1
sst 2 2 2
sst 3 3 3
sst 4 4 4
sst 5 5 5
sst 6 6 6
sst 7 7 7 

sll 0 1		// Test loading low bytes into each register
sll 1 2
sll 2 3
sll 3 4
sll 4 5
sll 5 6
sll 6 7
sll 7 8	 

vld 0 0 0	// Test loading vectors
vld 1 1 0
vld 2 2 0
vld 3 3 0
vld 4 4 0
vld 5 5 0
vld 6 6 0
vld 7 7 0	

smul 0 0 0	// Test scalar multiply
smul 1 1 1
smul 2 2 2
smul 3 3 3
smul 4 4 4
smul 5 5 5
smul 6 6 6
smul 7 7 7

vst 0 7 0	// Test storing vectors
vst 1 6 0
vst 2 5 0
vst 3 4 0
vst 4 3 0
vst 5 2 0
vst 6 1 0
vst 7 0 0	

vdot 0 0 0	// Test vector dot
vdot 1 1 1
vdot 2 2 2
vdot 3 3 3
vdot 4 4 4
vdot 5 5 5
vdot 6 6 6
vdot 7 7 7

@101
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001
#0001_0001_0001_0001

@202
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010
#0010_0010_0010_0010

@303
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011
#0011_0011_0011_0011

@404
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100
#0100_0100_0100_0100


@505
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101
#0101_0101_0101_0101

@606
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110
#0110_0110_0110_0110

@707
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111
#0111_0111_0111_0111

@808
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
#1000_1000_1000_1000
