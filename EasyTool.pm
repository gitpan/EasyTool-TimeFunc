package EasyTool;
use strict;
use warnings(FATAL=>'all');

#===================================
#===Module  : Framework::EasyTool-TimeFunc
#===Comment : time operate function
#===Require : Time::Local
#===================================

#===TODO: time zone supports
#===1.0.0(2006-06-12): first release

use Time::Local;

our $VERSION = 'TimeFunc-1.0.0';
sub foo{1};
sub _name_pkg_name{__PACKAGE__;}

#===========================================
#===options

	#default datetime format, in Adways China Office, we like '%04s/%02s/%02s %02s:%02s:%02s', and in Japan Office maybe they prefer '%04s/%02s/%02s %02s:%02s:%02s'
	#!THIS IS NOT EASY TO CONFIG,PLEASE DON'T DO BIG CHANGE
	#our $_DEFAULT_DATETIME_FORMAT='%04s/%02s/%02s %02s:%02s:%02s';
	
	
our $_TIMEFUNC_DEFAULT_DATETIME_FORMAT;
our $_TIMEFUNC_DEFAULT_DATE_FORMAT;
our $_TIMEFUNC_MIN_TIMESTAMP;
our $_TIMEFUNC_MAX_TIMESTAMP;

BEGIN{
	$_TIMEFUNC_DEFAULT_DATETIME_FORMAT='%04s-%02s-%02s %02s:%02s:%02s';
	$_TIMEFUNC_DEFAULT_DATE_FORMAT='%04s-%02s-%02s';

	$_TIMEFUNC_MIN_TIMESTAMP=31536000;   #'1971-01-01 00:00:00 GMT'
	$_TIMEFUNC_MAX_TIMESTAMP=2145916800; #max of int
};
#===========================================

#===time support function
#===support year from 1971 to 2037
#===if you want more function,please use EasyDateTime
#===the time zone used in these function is server local time zone

#===To use these function please 
#use Time::Local;

#===the 'time' in function name means time_str, please read the description of $time_str

#===$timestamp : unix timestamp, an integer like 946656000
#===$datetime  : date time string, a string, like '2004-08-28 08:06:00'
#===$date      : date string, a string like, like '2004-08-28'

#===$rh_offset : a hash represent the offset in two times
#===$rh_offset is a struct like {year=>0,month=>0,day=>0,hour=>0,min=>0,sec=>0}
#===if some item in $rh_offset is not set ,use zero instead, integer can be negative
#===one month: {month=>1} 
#===one day  : {day=>1}

#===$time_str

#Samples can be accepted
#	'2004-08-28 08:06:00' ' 2004-08-28 08:06:00 '
#	'2004-08-28T08:06:00' '2004/08/28 08:06:00'
#	'2004.08.28 08:06:00' '2004-08-28 08.06.00'
#	'04-8-28 8:6:0' '2004-08-28' '08:06:00'
#	'946656000'

#Which string can be accepted?
#	rule 0:an int represent seconds since the Unix Epoch (January 1 1970 00:00:00 GMT) can be accepted
#	rule 1:there can be some blank in the begin or end of DATETIME_STR e.g. ' 2004-08-28 08:06:00 '
#	rule 2:date can be separate by . / or - e.g. '2004/08/28 08:06:00'
#	rule 3:time can be separate by . or : e.g. '2004-08-28 08.06.00'
#	rule 4:date and time can be join by white space or 'T' e.g. '2004-08-28T08:06:00'
#	rule 5:can be (date and time) or (only date) or (only time) e.g. '2004-08-28' or '08:06:00'
#	rule 6:year can be 2 digits or 4 digits,other field can be 2 digits or 1 digit e.g. '04-8-28 8:6:0'
#	rule 7:if only the date be set then the time will be set to 00:00:00
#		if only the time be set then the date will be set to 2000-01-01

#===$template option
#===FORMAT
#%datetime   return string like '2004-08-28 08:06:00'
#%date       return string like '2004-08-28'
#%timestamp  return unix timestamp

#===YEAR
#%yyyy       A full numeric representation of a year, 4 digits(2004)
#%yy         A two digit representation of a year(04)

#===MONTH
#%MM         Numeric representation of a month, with leading zeros (01..12)
#%M          Numeric representation of a month, without leading zeros (1..12)

#===DAY
#%dd         Day of the month, 2 digits with leading zeros (01..31)
#%d          Day of the month without leading zeros (1..31)

#===HOUR
#%h12        12-hour format of an hour without leading zeros (1..12)
#%h          24-hour format of an hour without leading zeros (0..23)
#%hh12       12-hour format of an hour with leading zeros (01..12)
#%hh         24-hour format of an hour with leading zeros (00..23)
#%ap         a Lowercase Ante meridiem and Post meridiem  (am or pm)
#%AP         Uppercase Ante meridiem and Post meridiem (AM or PM)

#===MINUTE
#%mm         Minutes with leading zeros (00..59)
#%m          Minutes without leading zeros (0..59)

#===SECOND
#%ss         Seconds, with leading zeros (00..59)
#%s          Seconds, without leading zeros (0..59)


#add month 的陷阱
#5月31号加一个月，会die掉，有的时候你可能不会轻易发现这个问题，但务必请非常注意

##########################################################################

sub _time_func_is_int{
	my $param_count=scalar(@_);
	my ($str,$num,$max,$min)=(exists $_[0]?$_[0]:$_,undef,undef,undef);
	my ($true,$false) = (1,'');
	if($param_count==1||$param_count==2||$param_count==3){
		eval{$num=int($str);};
		if($@){undef $@;return defined(&_name_false)?&_name_false:'';}
		if($num ne $str){return defined(&_name_false)?&_name_false:'';}
		if($param_count==1){
			$max=2147483648;$min=-2147483648;
		}elsif($param_count==2){
			$max=2147483648;$min=$_[1];
		}elsif($param_count==3){
			$max=$_[2];$min=$_[1];
		}else{
			CORE::die '_time_func_is_int: BUG!';
		}
	
		if((!defined($min)||$num>=$min)&&(!defined($max)||$num<$max)){
			return $true;
		}else{
			return $false;
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'_time_func_is_int: param count should be 1, 2 or 3');
	}
}


#===$format_str=time_2_str($time_str[,$template])
#===time_2_str($time_str) return str sush as '2000-01-01 00:00:00'
#===time_2_str($time_str,'%yyyy-%MM-%dd') return str sush as '2000-01-01'
sub time_2_str {
	my $param_count=scalar(@_);
	if($param_count==1){
		if(!defined($_[0])){return undef;}
		local $_=time_2_timestamp($_[0]);
		$_=[localtime($_)];
		return sprintf($_TIMEFUNC_DEFAULT_DATETIME_FORMAT,$_->[5]+1900,$_->[4]+1,$_->[3],$_->[2],$_->[1],$_->[0]);
	}elsif($param_count==2){
		if(!defined($_[0])){return undef;}
		local $_=time_2_timestamp($_[0]);
		my $format_str=$_[1];
		if(!defined($format_str)){
			$_=[localtime($_)];
			return sprintf($_TIMEFUNC_DEFAULT_DATETIME_FORMAT,$_->[5]+1900,$_->[4]+1,$_->[3],$_->[2],$_->[1],$_->[0]);
		}
		my $t=[localtime($_)];
		my $map={
			ss=>sprintf('%02s',$t->[0]),
			s=>$t->[0],
			mm=>sprintf('%02s',$t->[1]),
			m=>$t->[1],
			AP=>$t->[2]>=12?'PM':'AM',
			ap=>$t->[2]>=12?'pm':'am',
			hh=>sprintf('%02s',$t->[2]),
			h=>$t->[2],
			hh12=>sprintf('%02s',$t->[2]>=12?($t->[2]-12):$t->[2]),
			h12=>$t->[2]>=12?($t->[2]-12):$t->[2],
			dd=>sprintf('%02s',$t->[3]),
			d=>$t->[3],
			MM=>sprintf('%02s',$t->[4]+1),
			M=>$t->[4]+1,
			yyyy=>$t->[5]+1900,
			yy=>($t->[5]+1900)%100,
			date=>sprintf($_TIMEFUNC_DEFAULT_DATE_FORMAT,$t->[5]+1900,$t->[4]+1,$t->[3]),
			datetime=>sprintf($_TIMEFUNC_DEFAULT_DATETIME_FORMAT,$t->[5]+1900,$t->[4]+1,$t->[3],$t->[2],$t->[1],$t->[0]),
			timestamp=>$_
		};

#AM and PM - What is Noon and Midnight?
#AM and PM start immediately after Midnight and Noon (Midday) respectively.
#This means that 00:00 AM or 00:00 PM (or 12:00 AM and 12:00 PM) have no meaning.
#Every day starts precisely at midnight and AM starts immediately after that point in time e.g. 00:00:01 AM (see also leap seconds)
#To avoid confusion timetables, when scheduling around midnight, prefer to use either 23:59 or 00:01 to avoid confusion as to which day is being referred to.
#It is after Noon that PM starts e.g. 00:00:01 PM (12:00:01)

		$format_str=~s/%timestamp/$map->{timestamp}/g;
		$format_str=~s/%datetime/$map->{datetime}/g;
		$format_str=~s/%date/$map->{date}/g;
		$format_str=~s/%yyyy/$map->{yyyy}/g;
		$format_str=~s/%hh12/$map->{hh12}/g;
		$format_str=~s/%h12/$map->{h12}/g;
		$format_str=~s/%ss/$map->{ss}/g;
		$format_str=~s/%mm/$map->{mm}/g;
		$format_str=~s/%AP/$map->{AP}/g;
		$format_str=~s/%ap/$map->{ap}/g;
		$format_str=~s/%hh/$map->{hh}/g;
		$format_str=~s/%dd/$map->{dd}/g;
		$format_str=~s/%MM/$map->{MM}/g;
		$format_str=~s/%yy/$map->{yy}/g;
		$format_str=~s/%h/$map->{h}/g;
		$format_str=~s/%M/$map->{M}/g;
		$format_str=~s/%d/$map->{d}/g;
		$format_str=~s/%m/$map->{m}/g;
		$format_str=~s/%s/$map->{s}/g;

		return $format_str;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'time_2_str: param count should be 1 or 2');
	}
}

#===$timestamp=time_2_timestamp($time_str)
#2000-01-01 00:00:00 +08:00   946656000
sub time_2_timestamp{
	my $param_count=scalar(@_);
	if($param_count==1){
		local $_ = shift;
		if(!defined($_)) {return undef;}
		if(/^\s*(\d{4}|\d{2})([\-\.\/])(\d{1,2})\2(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal(0,0,0,$4,$3-1,$1);};
			if($@){undef $@;CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'time_2_timestamp: unsupport time string format');}else{return $_;}
		}elsif(/^\s*(\d{4}|\d{2})([\-\.\/])(\d{1,2})\2(\d{1,2})(\x20+|T)(\d{1,2})([\:\.])(\d{1,2})\7(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal($9,$8,$6,$4,$3-1,$1);};
			if($@){undef $@;CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'time_2_timestamp: unsupport time string format');}else{return $_;}
		}elsif(/^\s*(\d{1,2})([\:\.])(\d{1,2})\2(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal($4,$3,$1,1,1-1,2000);};
			if($@){undef $@;CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'time_2_timestamp: unsupport time string format');}else{return $_;}
		}elsif(&_time_func_is_int($_,$_TIMEFUNC_MIN_TIMESTAMP,$_TIMEFUNC_MAX_TIMESTAMP)){
			return $_;
		}else{
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'time_2_timestamp: unsupport time string format');
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'time_2_timestamp: param count should be 1');
	}
}

#===$flag=is_time($time_str)
sub is_time{
	my $param_count=scalar(@_);
	if($param_count==1){
		my ($true,$false) = (1,'');
		local $_ = $_[0];
		if(!defined($_)){return $false;}#if undef
		if(ref $_ ne ''){return $false;}#if not a scalar
		if(/^\s*(\d{4}|\d{2})([\-\.\/])(\d{1,2})\2(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal(0,0,0,$4,$3-1,$1);};
			if($@){undef $@;return $false;}else{return $true;}
		}elsif(/^\s*(\d{4}|\d{2})([\-\.\/])(\d{1,2})\2(\d{1,2})(\x20+|T)(\d{1,2})([\:\.])(\d{1,2})\7(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal($9,$8,$6,$4,$3-1,$1);};
			if($@){undef $@;return $false;}else{return $true;}
		}elsif(/^\s*(\d{1,2})([\:\.])(\d{1,2})\2(\d{1,2})\s*$/){
			eval{$_=Time::Local::timelocal($4,$3,$1,1,1-1,2000);};
			if($@){undef $@;return $false;}else{return $true;}
		}elsif(&_time_func_is_int($_,$_TIMEFUNC_MIN_TIMESTAMP,$_TIMEFUNC_MAX_TIMESTAMP)){
			return $true;
		}else{
			return $false;
		}
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'is_time: param count should be 1');
	}
}

#===$time=hash_2_timestamp({year=>2000,month=>1,day=>1,hour=>0,min=>0,sec=>0})
#===if some item not set ,default value will be used
sub hash_2_timestamp{
	my $param_count=scalar(@_);
	if($param_count==1){
		local $_ = [];
		my $rh_time=$_[0];
		if(!defined($rh_time)){return undef;}
		$_->[5]=defined($rh_time->{'year'})?_time_func_is_int($rh_time->{'year'})?$_[0]->{'year'}:CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'hash_2_timestamp: not a valid time'):2000;
		$_->[4]=defined($rh_time->{'month'})?_time_func_is_int($rh_time->{'month'})?$_[0]->{'month'}:CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'hash_2_timestamp: not a valid time'):1;
		$_->[3]=defined($rh_time->{'day'})?_time_func_is_int($rh_time->{'day'})?$_[0]->{'day'}:CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'hash_2_timestamp: not a valid time'):1;
		$_->[2]=defined($rh_time->{'hour'})?_time_func_is_int($rh_time->{'hour'})?$_[0]->{'hour'}:CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'hash_2_timestamp: not a valid time'):0;
		$_->[1]=defined($rh_time->{'min'})?_time_func_is_int($rh_time->{'min'})?$_[0]->{'min'}:CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'hash_2_timestamp: not a valid time'):0;
		$_->[0]=defined($rh_time->{'sec'})?_time_func_is_int($rh_time->{'sec'})?$_[0]->{'sec'}:CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'hash_2_timestamp: not a valid time'):0;
		eval{$_=Time::Local::timelocal($_->[0],$_->[1],$_->[2],$_->[3],$_->[4]-1,$_->[5]);};
		if($@){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'hash_2_timestamp: not a valid time');}
		return $_;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'hash_2_timestamp: param count should be 1');
	}
}

#===$rh_time=time_2_hash($time_str)
#===$rh_time is a struct like {year=>2000,month=>1,day=>1,hour=>0,min=>0,sec=>0}
sub time_2_hash{
	my $param_count=scalar(@_);
	if($param_count==1){
		if(!defined($_[0])){return undef;}
		local $_=[localtime(time_2_timestamp($_[0]))];
		return {year=>$_->[5]+1900,month=>$_->[4]+1,day=>$_->[3],hour=>$_->[2],min=>$_->[1],sec=>$_->[0]};
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'time_2_hash: param count should be 1');
	}
}

#===$timestamp=&now();
#===same as CORE::time();
sub now{
	CORE::time();
}

#===$timestamp=&time();
#===same as CORE::time();
sub time{
	CORE::time();
}

#===$date=&date_now();
sub date_now{
	local $_=[localtime(&now())];
	sprintf($_TIMEFUNC_DEFAULT_DATE_FORMAT,$_->[5]+1900,$_->[4]+1,$_->[3]);
}

#===$datetime=&datetime_now();
sub datetime_now{
	local $_=[localtime(&now())];
	sprintf($_TIMEFUNC_DEFAULT_DATETIME_FORMAT,$_->[5]+1900,$_->[4]+1,$_->[3],$_->[2],$_->[1],$_->[0]);
}

#===$timestamp=&timestamp_now();
#===same as now();
sub timestamp_now{
	&now();
}

#===$day_count=day_of_month($year,$month)
sub day_of_month{
	my $param_count=scalar(@_);
	if($param_count==2){
		if(!&_time_func_is_int($_[0],1901,2038)){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'day_of_month: $1 should be integer in [1901,2037]');
		}
		if(!&_time_func_is_int($_[1],1,13)){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'day_of_month: $2 should be integer in [1,12]');
		}
		local $_=[31,28,31,30,31,30,31,31,30,31,30,31]->[$_[1]-1];
		++$_ if $_[1] == 2 && (!($_[0] % 4));
		return $_;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'day_of_month: param count should be 2');
	}
}

#===$time_zone=localtimezone()
sub localtimezone {
	return int ((timegm(0,0,0,1,0,2000)-timelocal(0,0,0,1,0,2000))/3600);
}

#===$timestamp=timestamp_add($time_str,$rh_offset)
sub timestamp_add{
	my $param_count=scalar(@_);
	if($param_count==2){
		my ($month,$sec)=(0,0);
		if(!is_time($_[0])){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'timestamp_add: $1 not a valid time_str');
		}
		if(ref $_[1] ne 'HASH'){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'timestamp_add: $2 should be a hash_ref');
		}
		$month+=12*(_time_func_is_int($_[1]->{'year'})?$_[1]->{'year'}:0);
		$month+=_time_func_is_int($_[1]->{'month'})?$_[1]->{'month'}:0;
		$sec+=86400*(_time_func_is_int($_[1]->{'day'})?$_[1]->{'day'}:0);
		$sec+=3600*(_time_func_is_int($_[1]->{'hour'})?$_[1]->{'hour'}:0);
		$sec+=60*(_time_func_is_int($_[1]->{'min'})?$_[1]->{'min'}:0);
		$sec+=_time_func_is_int($_[1]->{'sec'})?$_[1]->{'sec'}:0;
		my $t=[localtime(time_2_timestamp($_[0])+$sec)];
		$t->[5]=int($t->[5]+($t->[4]+$month)/12);
		$t->[4]= ($t->[4]+$month)%12;
		eval{$t=Time::Local::timelocal($t->[0],$t->[1],$t->[2],$t->[3],$t->[4],$t->[5]);};
		if($@){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'timestamp_set: not a valid time');}
		return $t;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'timestamp_add: param count should be 2');
	}
}


#===$timestamp=timestamp_set($time_str,$rh_time)
sub timestamp_set{
	my $param_count=scalar(@_);
	if($param_count==2){
		my $t=[localtime(time_2_timestamp($_[0]))];
		my $rh_time=$_[1];
		$t->[5]=_time_func_is_int($rh_time->{'year'})?$rh_time->{'year'}:$t->[5]+1900;
		$t->[4]=_time_func_is_int($rh_time->{'month'})?$rh_time->{'month'}:$t->[4]+1;
		$t->[3]=_time_func_is_int($rh_time->{'day'})?$rh_time->{'day'}:$t->[3];
		$t->[2]=_time_func_is_int($rh_time->{'hour'})?$rh_time->{'hour'}:$t->[2];
		$t->[1]=_time_func_is_int($rh_time->{'min'})?$rh_time->{'min'}:$t->[1];
		$t->[0]=_time_func_is_int($rh_time->{'sec'})?$rh_time->{'sec'}:$t->[0];
		eval{$t=Time::Local::timelocal($t->[0],$t->[1],$t->[2],$t->[3],$t->[4]-1,$t->[5]);};
		if($@){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'timestamp_set: not a valid time');}
		return $t;
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'timestamp_set: param count should be 2');
	}
}

#===$timestamp=date_add($time_str,$rh_offset)
sub date_add{
	my $param_count=scalar(@_);
	if($param_count==2){
		my ($month,$sec)=(0,0);
		if(!is_time($_[0])){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'date_add: $1 not a valid time_str');
		}
		if(ref $_[1] ne 'HASH'){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'date_add: $2 should be a hash_ref');
		}
		$month+=12*(_time_func_is_int($_[1]->{'year'})?$_[1]->{'year'}:0);
		$month+=_time_func_is_int($_[1]->{'month'})?$_[1]->{'month'}:0;
		$sec+=86400*(_time_func_is_int($_[1]->{'day'})?$_[1]->{'day'}:0);
		$sec+=3600*(_time_func_is_int($_[1]->{'hour'})?$_[1]->{'hour'}:0);
		$sec+=60*(_time_func_is_int($_[1]->{'min'})?$_[1]->{'min'}:0);
		$sec+=_time_func_is_int($_[1]->{'sec'})?$_[1]->{'sec'}:0;
		my $t=[localtime(time_2_timestamp($_[0])+$sec)];
		$t->[5]=int($t->[5]+($t->[4]+$month)/12);
		$t->[4]= ($t->[4]+$month)%12;
		eval{local $_=Time::Local::timelocal($t->[0],$t->[1],$t->[2],$t->[3],$t->[4],$t->[5]);};
		if($@){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'date_add: not a valid time');}
		return sprintf($_TIMEFUNC_DEFAULT_DATE_FORMAT,$t->[5]+1900,$t->[4]+1,$t->[3]);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'date_add: param count should be 2');
	}
}

#===$date=date_set($time_str,$rh_time)
sub date_set{
	my $param_count=scalar(@_);
	if($param_count==2){
		my $t=[localtime(time_2_timestamp($_[0]))];
		my $rh_time=$_[1];
		$t->[5]=_time_func_is_int($rh_time->{'year'})?$rh_time->{'year'}:$t->[5]+1900;
		$t->[4]=_time_func_is_int($rh_time->{'month'})?$rh_time->{'month'}:$t->[4]+1;
		$t->[3]=_time_func_is_int($rh_time->{'day'})?$rh_time->{'day'}:$t->[3];
		$t->[2]=_time_func_is_int($rh_time->{'hour'})?$rh_time->{'hour'}:$t->[2];
		$t->[1]=_time_func_is_int($rh_time->{'min'})?$rh_time->{'min'}:$t->[1];
		$t->[0]=_time_func_is_int($rh_time->{'sec'})?$rh_time->{'sec'}:$t->[0];
		eval{local $_=Time::Local::timelocal($t->[0],$t->[1],$t->[2],$t->[3],$t->[4]-1,$t->[5]);};
		if($@){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_set: not a valid time');}
		return sprintf($_TIMEFUNC_DEFAULT_DATE_FORMAT,$t->[5],$t->[4],$t->[3]);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'date_set: param count should be 2');
	}
}

#===$datetime=datetime_add($time_str,$rh_offset)
sub datetime_add{
	my $param_count=scalar(@_);
	if($param_count==2){
		my ($month,$sec)=(0,0);
		if(!is_time($_[0])){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_add: $1 not a valid time_str');
		}
		if(ref $_[1] ne 'HASH'){
			CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_add: $2 should be a hash_ref');
		}
		$month+=12*(_time_func_is_int($_[1]->{'year'})?$_[1]->{'year'}:0);
		$month+=_time_func_is_int($_[1]->{'month'})?$_[1]->{'month'}:0;
		$sec+=86400*(_time_func_is_int($_[1]->{'day'})?$_[1]->{'day'}:0);
		$sec+=3600*(_time_func_is_int($_[1]->{'hour'})?$_[1]->{'hour'}:0);
		$sec+=60*(_time_func_is_int($_[1]->{'min'})?$_[1]->{'min'}:0);
		$sec+=_time_func_is_int($_[1]->{'sec'})?$_[1]->{'sec'}:0;
		my $t=[localtime(time_2_timestamp($_[0])+$sec)];
		$t->[5]=int($t->[5]+($t->[4]+$month)/12);
		$t->[4]= ($t->[4]+$month)%12;
		eval{local $_=Time::Local::timelocal($t->[0],$t->[1],$t->[2],$t->[3],$t->[4],$t->[5]);};
		if($@){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_add: not a valid time');}
		return sprintf($_TIMEFUNC_DEFAULT_DATETIME_FORMAT,$t->[5]+1900,$t->[4]+1,$t->[3],$t->[2],$t->[1],$t->[0]);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_add: param count should be 2');
	}
}

#===$date=date_set($time_str,$rh_time)
sub datetime_set{
	my $param_count=scalar(@_);
	if($param_count==2){
		my $t=[localtime(time_2_timestamp($_[0]))];
		my $rh_time=$_[1];
		$t->[5]=_time_func_is_int($rh_time->{'year'})?$rh_time->{'year'}:$t->[5]+1900;
		$t->[4]=_time_func_is_int($rh_time->{'month'})?$rh_time->{'month'}:$t->[4]+1;
		$t->[3]=_time_func_is_int($rh_time->{'day'})?$rh_time->{'day'}:$t->[3];
		$t->[2]=_time_func_is_int($rh_time->{'hour'})?$rh_time->{'hour'}:$t->[2];
		$t->[1]=_time_func_is_int($rh_time->{'min'})?$rh_time->{'min'}:$t->[1];
		$t->[0]=_time_func_is_int($rh_time->{'sec'})?$rh_time->{'sec'}:$t->[0];
		eval{local $_=Time::Local::timelocal($t->[0],$t->[1],$t->[2],$t->[3],$t->[4]-1,$t->[5]);};
		if($@){CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_set: not a valid time');}
		return sprintf($_TIMEFUNC_DEFAULT_DATETIME_FORMAT,$t->[5],$t->[4],$t->[3],$t->[2],$t->[1],$t->[0]);
	}else{
		CORE::die((defined(&_name_pkg_name)?&_name_pkg_name.'::':'').'datetime_set: param count should be 2');
	}
}

1;

__END__

=head1 NAME

EasyTool-TimeFunc - the time operate related function part of EasyTool

=head1 SYNOPSIS

	use EasyTool;
	
	if(defined(&EasyTool::foo)){
		print "lib is included";
	}else{
		print "lib is not included";
	}
	
	print EasyTool::time_2_str('1983-03-07 01:02:03','%yyyy-%MM-%%dd');
	print EasyTool::time_2_str('1983-03-07 01:02:03');
	print EasyTool::time_2_str('1983-03-07');
	print EasyTool::time_2_str('2004-08-28T08:06:00');
	print EasyTool::time_2_str('946656000');
	print EasyTool::time_2_str(' 1983-03-07 ');
	print EasyTool::time_2_str('1983-03-07T01:02:03');


	print EasyTool::is_time('1983-03-07 01:02:03');
	print  EasyTool::time_2_timestamp('1983-03-07 01:02:03');
	print EasyTool::hash_2_timestamp({year=>1983,month=>3,day=>7,hour=>1,min=>2,sec=>3});
	$rh_time=EasyTool::time_2_hash('1983-03-07 01:02:03'); #{year=>1983,month=>3,day=>7,hour=>1,min=>2,sec=>3}
	
	print EasyTool::now();
	print EasyTool::time();
	print EasyTool::datetime_now();
	print EasyTool::date_now();

	print day_of_month(2000,2); #29

	print EasyTool::timestamp_set('1983-03-07 01:02:03',{year=>1984,month=>5,day=>10,hour=>5,min=>7,sec=>9});#maybe 453013629
	print EasyTool::datetime_set('1983-03-07 01:02:03',{year=>1984,day=>10,min=>7});#'1984-03-10 01:07:03'
	print EasyTool::date_set('1983-03-07 01:02:03'',{month=>5,hour=>5,sec=>9});#'1983-05-07'
	
	print EasyTool::timestamp_add('1983-03-07 01:02:03',{year=>1,month=>2,day=>3,hour=>4,min=>5,sec=>6});#maybe 453013629
	$datetime=EasyTool::datetime_add('1983-03-07 01:02:03',{year=>1,day=>3,min=>5});#'1984-03-10 01:07:03'
	$date=EasyTool::date_add('1983-03-07 01:02:03',{month=>2,hour=>4,sec=>6});#'1983-05-07'
	
I<The synopsis above only lists the major methods and parameters.>

=head1 DESCRIPTION 

The EasyTool module aims to provide a easy to use, easy to port function set

you can copy and paste some function to embed into your code as easy as possiable
youc can also make some modification on function as you need

this package inlcude the time operate related function part of EasyTool

=head2 Fisrt of All

	support time from 1971 to 2037
	if you want more function,please use EasyDateTime
	the time zone used in these function is server local time zone

=head2 Notation and Conventions 

=head3 function name

	the 'time' in function name means time_str, please read the description of $time_str

=head3 param and return value

	$time_str: $time_str is the string as be accept as a time 

		Samples can be accepted
		'2004-08-28 08:06:00' ' 2004-08-28 08:06:00 '
		'2004-08-28T08:06:00' '2004/08/28 08:06:00'
		'2004.08.28 08:06:00' '2004-08-28 08.06.00'
		'04-8-28 8:6:0' '2004-08-28' '08:06:00'
		'946656000'

		Which string can be accepted?
		rule 0: Unix Timestamp, an int represent seconds since the Unix Epoch (January 1 1970 00:00:00 GMT) can be accepted
		rule 1: there can be some blank in the begin or end of string e.g. ' 2004-08-28 08:06:00 '
		rule 2: date can be separate by . / or - e.g. '2004/08/28 08:06:00'
		rule 3: time can be separate by . or : e.g. '2004-08-28 08.06.00'
		rule 4: date and time can be join by white space or 'T' e.g. '2004-08-28T08:06:00'
		rule 5: can be (date and time) or (only date) or (only time) e.g. '2004-08-28' or '08:06:00'
		rule 6: year can be 2 digits or 4 digits,other field can be 2 digits or 1 digit e.g. '04-8-28 8:6:0'
		rule 7: if only the date be set then the time will be set to 00:00:00
		if only the time be set then the date will be set to 2000-01-01
	
	
	$timestamp : unix timestamp, an integer like 946656000
	$datetime  : date time string, a string, like '2004-08-28 08:06:00'
	$date      : date string, a string like, like '2004-08-28'

	$rh_time   : a hash represent a time
	$rh_time is a struct like {year=>2000,month=>1,day=>1,hour=>0,min=>0,sec=>0}
	if some item in $rh_time is not set ,use default value instead
	default values: year=>2000,month=>1,day=>1,hour=>0,min=>0,sec=>0
	
	$rh_offset : a hash represent the offset in two times
	$rh_offset is a struct like {year=>0,month=>0,day=>0,hour=>0,min=>0,sec=>0}
	if some item in $rh_offset is not set ,use zero instead, integer can be negative
	one month: {month=>1} 
	one day  : {day=>1}
	one month and one day: {month=>1,day=>1}
	when you add a time with $rh_offset such as {year=>0,month=>0,day=>0,hour=>0,min=>0,sec=>0}, it will add second first,then
		miniute, hour, day, month, year
	
	$template option:
	#===FORMAT
	#%datetime   return string like '2004-08-28 08:06:00'
	#%date       return string like '2004-08-28'
	#%timestamp  return unix timestamp
	
	#===YEAR
	#%yyyy       A full numeric representation of a year, 4 digits(2004)
	#%yy         A two digit representation of a year(04)
	
	#===MONTH
	#%MM         Numeric representation of a month, with leading zeros (01..12)
	#%M          Numeric representation of a month, without leading zeros (1..12)
	
	#===DAY
	#%dd         Day of the month, 2 digits with leading zeros (01..31)
	#%d          Day of the month without leading zeros (1..31)
	
	#===HOUR
	#%h12        12-hour format of an hour without leading zeros (1..12)
	#%h          24-hour format of an hour without leading zeros (0..23)
	#%hh12       12-hour format of an hour with leading zeros (01..12)
	#%hh         24-hour format of an hour with leading zeros (00..23)
	#%ap         a Lowercase Ante meridiem and Post meridiem  (am or pm)
	#%AP         Uppercase Ante meridiem and Post meridiem (AM or PM)
	
	#===MINUTE
	#%mm         Minutes with leading zeros (00..59)
	#%m          Minutes without leading zeros (0..59)
	
	#===SECOND
	#%ss         Seconds, with leading zeros (00..59)
	#%s          Seconds, without leading zeros (0..59)
	
	$bool: 1 for true and '' for false

=head3 extra knowledge
	
	AM and PM - What is Noon and Midnight?
	AM and PM start immediately after Midnight and Noon (Midday) respectively.
	This means that 00:00 AM or 00:00 PM (or 12:00 AM and 12:00 PM) have no meaning.
	Every day starts precisely at midnight and AM starts immediately after that point in time e.g. 00:00:01 AM (see also leap seconds)
	To avoid confusion timetables, when scheduling around midnight, prefer to use either 23:59 or 00:01 to avoid confusion as to which day is being referred to.
	It is after Noon that PM starts e.g. 00:00:01 PM (12:00:01)

=head1 basic function

=head2 foo - check whether this module is be used

	if(defined(&EasyTool::foo)){
		print "lib is included";
	}else{
		print "lib is not included";
	}

=head2 time_2_str - format output time string

	$format_str=EasyTool::time_2_str($time_str[,$template])
	time_2_str($time_str) return str sush as '2000-01-01 00:00:00'
	time_2_str($time_str,'%yyyy-%MM-%dd') return str sush as '2000-01-01'

=head2 is_time - whether this is a valid time string

	$bool=EasyTool::is_time($time_str)

=head2 time_2_timestamp - input is $time_str output is unix timestamp

	$timestamp=EasyTool::time_2_timestamp($time_str)

=head2 hash_2_timestamp - input is hash output is unix timestamp

	$timestamp=EasyTool::hash_2_timestamp($rh_time)

=head2 time_2_hash

	$rh_time=EasyTool::time_2_hash($time_str)

=head2 get time of now

	$timestamp=EasyTool::now();
	$timestamp=EasyTool::time();
	$datetime=EasyTool::datetime_now();
	$date=EasyTool::date_now();

=head2 day_of_month - get day count of specified month

	$day_count=day_of_month($year,$month)

=head2 set time funcion
	
	$timestamp=EasyTool::timestamp_set($time_str,$rh_time);
	$date=EasyTool::date_set($time_str,$rh_time);
	$datetime=EasyTool::datetime_add($time_str,$rh_offset)

=head2 time operate funcion

	$timestamp=EasyTool::timestamp_add($time_str,$rh_offset);
	$datetime=EasyTool::datetime_add($time_str,$rh_offset);
	$date=EasyTool::date_add($time_str,$rh_offset)

=head1 COPYRIGHT

The EasyTool module is Copyright (c) 2003-2005 QIAN YU.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.
