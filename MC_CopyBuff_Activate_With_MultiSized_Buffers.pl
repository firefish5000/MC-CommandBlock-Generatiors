#!/usr/bin/perl
use strict;
use warnings;
use feature qw{say switch};
use experimental qw{switch};
use Math::Expression;
my @LOOP_RUN=();
my %DECLARE=(EmptyList=>[()]);
my $MATH = Math::Expression->new(VarHash=>\%DECLARE);
my $InDeclare=-1;
my @Lines=();
my $DBUG=0;
my $PRINT_INIT=1;
my $PRINT_DECLARE=1;
my $PRINT_DIST=1;
my $PASTE=0;
sub MathObj {
	return $MATH->Parse(@_);
}
sub SetVar {
	return $MATH->VarSetScalar(@_);
}
sub SetArr {
	return $MATH->VarSetFun(@_);
}
sub GetVars { # Map removes Keys used soly by Math::Expression, sort sorts longest keys first,
	# so substitution won't cause problems with keys like 'KEYNAME' and KEYNAME_ButWithMoreName
	return sort {length($b) <=> length($a) } map {($_ ne "_TIME" && $_ ne "EmptyList") ? $_ : () } keys %DECLARE;
}
sub GetVals {
	my @val = $MATH->VarGetFun(@_);
	#return $val[0];
	return (scalar(@val) <1) ? "ARRAY IS EMPTY" : @val;
}
sub GetVal {
	my @val = $MATH->VarGetFun(@_);
	#return $val[0];
	return (scalar(@val) <1) ? "ARRAY IS EMPTY" : (scalar(@val) == 1) ? $val[0] : "MULTIPLE VALUES";
}
sub MathScalar {
	return $MATH->ParseToScalar(@_);
}
while (<DATA>) {
	if (/^---INIT---/) {
		$InDeclare=2;
		next;
	}
	if (/^---DECLARE---/) {
		$InDeclare=1;
		next;
	}
	if (/^---/) {
		$InDeclare=0;
		#$MATH->EvalTree();
		#say "----------";
		next;
	}
	if (/^#/) {
		next;
	}
	if (/\S/) {
		if($InDeclare == 2) {
			MathScalar($_);
		}
		elsif($InDeclare == 1) {
			push(@LOOP_RUN,MathObj($_));
		}
	}
	if (/./) {
		if($InDeclare == 0) {
			chomp($_);
			push(@Lines,$_);
			#foreach my $var (GetVars()) {
			#	s{$var}{MathScalar($var)}ge;
			#};
			#say "\n",$_;
		}
	}
}
Read_Args();
if ($PRINT_INIT) {
	say "-------INIT-------";
	foreach my $var (GetVars()) {
		say $var, "=", join(q{,},GetVals($var));
	}
}
my $HasPrintedCommand=0;
foreach my $Dist (GetVals('MOVE_DISTS')) {
	if ($PRINT_DIST) {
		say "-----------------------";
		say "       MOVE $Dist      ";
		say "-----------------------";
	}
	MathScalar("MOVE_DIST:=$Dist");
	foreach my $Selected (GetVals('SELECT_CORDS')) {
		MathScalar("SELECT_X:=0");
		MathScalar("SELECT_Y:=0");
		MathScalar("SELECT_Z:=0");
		MathScalar("SELECT_$Selected:=1");
		foreach my $dec (@LOOP_RUN) {
			$MATH->Eval($dec);
		}
		if ($PRINT_DECLARE) {
			say "-----DECLARE-----";
			if ($DBUG) {
				foreach my $var (GetVars()) {
					say $var, "=", GetVal($var);
				}
			}
			say "Move $Selected over " . GetVal('MOVE_DIST');
			say "-----------------";
		}
		foreach my $line_orig (@Lines) {
			my $line=$line_orig;
			foreach my $var (GetVars()) {
				#s{$var}{MathScalar($var)}ge;
				$line =~ s{$var}{GetVal($var)}ge;
			};
			if ($PASTE) {
				print ("\n\n"x$HasPrintedCommand,$line);
			}
			else {
				say ("\n"x$HasPrintedCommand,$line);
			}
			$HasPrintedCommand=1;
			#say $line;
		}
	}
}
sub PrintHelp() {
	say "I appologize if this help is incomplete, outdated, or unhelpfull.";
	print << "HEREHELP";
-h --help
	Prints this help message
-D --debug
	Prints DECLARE variables, which are set once for every Cordinate for every Distance. Note this is far more verbose than the normal declare header.
--no-init-headers
	Surpresses INIT header, which tells you what commands we are going to generate
--no-declare-header
	Surpresses declare header, which tells you which Cordinate and Distance the commands following are for.
--no-dist-header
	Surpresses the large distance header.
--paste
	Surpresses the all headers, and trailing newline. MC-Edit (Unified) Paste ready. May be passed straight to xclip, xsel, or similar.
DISTS <distance1>[,<distance2>,<distance3>...]
DISTS <distance1>[,<distance2>,<distance3>...]
	Specify distances for the commands we will generate
CORDS X[(,Y,Z)|(,Z)] | Y[,Z] | Z
	Specify axies that we will generate comands for.
CheckSize <Size>
	Specifies how many blocks thick we will check for the player at the appropriate distance.
HEREHELP

}
sub Read_Args {
	PARSE_ARGUMENTS:
	while (${ARGV[0]}) { # While ARGV[0] exist
		given (${ARGV[0]}) { # check if ARGV[0] Value
			when (/^-h$|^--help$/) {
				PrintHelp();
				exit;
			}
			#when (/^-p$|^--pretend$/) {
			#	$Pretend=1;
			#	shift @ARGV;
			#}
			when (/^-D$|^--debug$/) {
				$DBUG++;
				shift @ARGV;
				#BCscripts::Debug::Func::Reconfig(Debug=>$Debug);
			}
			when (/^--no-init-header$/) {
				$PRINT_INIT=0;
				shift @ARGV;
			}
			when (/^--no-declare-header$/) {
				$PRINT_DECLARE=0;
				shift @ARGV;
			}
			when (/^--paste$/) {
				$PRINT_INIT=0;
				$PRINT_DECLARE=0;
				$PRINT_DIST=0;
				$PASTE=1;
				shift @ARGV;
			}
			when (/^--no-dist-header$/) {
				$PRINT_DIST=0;
				shift @ARGV;
			}
			when ('DISTS') {
				shift @ARGV;
				MathScalar("MOVE_DISTS:=" . shift @ARGV);
			}
			when ('CHECK_SIZE') {
				shift @ARGV;
				MathScalar("SELECTED_CHECK_SIZE:=" . shift @ARGV);
			}
			when ('CORDS') {
				shift @ARGV;
				MathScalar(q{SELECT_CORDS:="} . join(q{","}, split(q{,},uc(shift @ARGV))) . q{"} );
			}
#			when ('') {
#				shift @ARGV;
#				MathScalar("MOVE_DIST:=" . shift @ARGV);
#			}
			when ('--') {
				shift @ARGV;
				last PARSE_ARGUMENTS;
			}
			default {
				PrintHelp();
				exit;
			}
		}
	}
	return 0;
}
__DATA__
---INIT---
MOVE_DIST:=1
MOVE_DISTS:=1,2,3,4,5,6,7,8,9,10
# SELECT_SIZES, Size of area 1 CopyBuff of type Selects and clones.
# A Chunk is XZ 16x16.
# CENTER_SELECT
CENTER_SELECT_SIZES:=[
	1,1,1,
	3,3,3,
	5,5,5,
	10,10,10,
	16,1,1,
	16,16,1,
	16,16,16,
	5,5,5,
]
X_SELECT_SIZE:=1
X_SELECT_SIZES:=1,2,3,4,5,6,7,8,9,10
Y_SELECT_SIZE:=1
Y_SELECT_SIZES:=1,2,3,4,5,6,7,8,9,10
Z_SELECT_SIZE:=1
Z_SELECT_SIZES:=1,2,3,4,5,6,7,8,9,10
START_MOVE_DIST:=1
END_MOVE_DIST:=1
SELECTED_CHECK_SIZE:=2
UNSELECTED_CHECK_SIZE:=-50
SELECT_CORDS:="X","Y","Z"
SELECT_X:=0
SELECT_Y:=0
SELECT_Z:=0

---DECLARE---
X_CHECK_SIZE:=UNSELECTED_CHECK_SIZE
Y_CHECK_SIZE:=UNSELECTED_CHECK_SIZE
Z_CHECK_SIZE:=UNSELECTED_CHECK_SIZE
if(SELECT_X) { X_CHECK_SIZE:=SELECTED_CHECK_SIZE }
if(SELECT_Y) { Y_CHECK_SIZE:=SELECTED_CHECK_SIZE }
if(SELECT_Z) { Z_CHECK_SIZE:=SELECTED_CHECK_SIZE }

SELECTED_PLAYER_START:= (MOVE_DIST+1)*-1 + SELECTED_CHECK_SIZE/2
# Unselected
X_PLAYER_START:=X_CHECK_SIZE/2
Y_PLAYER_START:=Y_CHECK_SIZE/2
Z_PLAYER_START:=Z_CHECK_SIZE/2
# FIXME SELECTED
if(SELECT_X) { X_PLAYER_START:=SELECTED_PLAYER_START }
if(SELECT_Y) { Y_PLAYER_START:=SELECTED_PLAYER_START }
if(SELECT_Z) { Z_PLAYER_START:=SELECTED_PLAYER_START }

SELECTED_BUFF_END:=-SELECTED_CHECK_SIZE
if (MOVE_DIST < 0) { SELECTED_BUFF_END:=SELECTED_CHECK_SIZE }
X_BUFF_END:=-X_CHECK_SIZE
Y_BUFF_END:=-Y_CHECK_SIZE
Z_BUFF_END:=-Z_CHECK_SIZE
# FIXME SELECTED
if(SELECT_X) { X_BUFF_END:=SELECTED_BUFF_END }
if(SELECT_Y) { Y_BUFF_END:=SELECTED_BUFF_END }
if(SELECT_Z) { Z_BUFF_END:=SELECTED_BUFF_END }

X_CHECK_POS:=0
Y_CHECK_POS:=0
Z_CHECK_POS:=0
if(SELECT_X) { X_CHECK_POS:=-MOVE_DIST }
if(SELECT_Y) { Y_CHECK_POS:=-MOVE_DIST }
if(SELECT_Z) { Z_CHECK_POS:=-MOVE_DIST }

X_SET_POS:=0
Y_SET_POS:=0
Z_SET_POS:=0
if(SELECT_X) { X_SET_POS:=MOVE_DIST }
if(SELECT_Y) { Y_SET_POS:=MOVE_DIST }
if(SELECT_Z) { Z_SET_POS:=MOVE_DIST }

# NOTE: Both ("") and ('') will have variable names expanded.
ABS_MOVE_DIST:=abs(MOVE_DIST)
STR_SELECT_PLAYERS:='@p[score_T_VanilaEditor_min=0,score_A_ExtndCopyBuff_min=1,score_A_MoveDist_min=ABS_MOVE_DIST,score_A_MoveDist=ABS_MOVE_DIST]'
STR_SELECT_CONTROL_BUFFER_COND:='score_T_ContBuff_min=1,dx=X_BUFF_END,dy=Y_BUFF_END,dz=Z_BUFF_END,c=1'
STR_SELECT_COPY_BUFFER_COND:='score_T_CopyBuff_min=1'
STR_SELECT_COPY_BUFFER_FRAME_COND:='type=ItemFrame,name=COPY_BUFF_FRAME'
-----

/execute STR_SELECT_PLAYERS ~X_PLAYER_START ~Y_PLAYER_START ~Z_PLAYER_START /execute @e[STR_SELECT_CONTROL_BUFFER_COND] ~ ~ ~ /execute @e[STR_SELECT_COPY_BUFFER_COND] ~X_CHECK_POS ~Y_CHECK_POS ~Z_CHECK_POS /scoreboard players set @e[STR_SELECT_COPY_BUFFER_COND,dx=0,dy=0,dz=0] V_OverlapWait 1

/execute STR_SELECT_PLAYERS ~X_PLAYER_START ~Y_PLAYER_START ~Z_PLAYER_START /execute @e[STR_SELECT_CONTROL_BUFFER_COND] ~ ~ ~ /execute @e[STR_SELECT_COPY_BUFFER_COND,score_V_ExtndConflict=0] ~ ~ ~ /clone ~ ~ ~ ~ ~ ~ ~X_SET_POS ~Y_SET_POS ~Z_SET_POS {Invulnerable:1b,Invisible:1b,NoGravity:1b,CustomName:"COPY_BUFF_FRAME",CustomNameVisible:true,PersistenceRequired:0b}

/scoreboard players set @e[STR_SELECT_COPY_BUFFER_COND] V_ExtndConflict 0

/execute STR_SELECT_PLAYERS ~X_PLAYER_START ~Y_PLAYER_START ~Z_PLAYER_START /tp @e[STR_SELECT_CONTROL_BUFFER_COND] ~X_SET_POS ~Y_SET_POS ~Z_SET_POS
