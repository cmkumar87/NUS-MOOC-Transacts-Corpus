package Model;

# Configuration
use strict;
use warnings;

##
#
# Author : Muthu Kumar C
# Created in May, 2014
#
##

# Dependencies
# External libraries
use DBI;

sub getDBHandle{
	# Set up database connection globally
	my ($path,$unicode,$dbtype,$dbname) = @_;
	my $uname;	
	my $pswd; 	
	my $dsn;
	
	if(!defined $dbtype){
	#sqlite
		$uname = 'foo';
		$pswd  = '';
		$dsn = "dbi:SQLite:dbname=$path/$dbname.db";
	}
	elsif($dbtype eq 'mysql'){
		#mysql
		$uname = 'root';
		$pswd  = 'root';
		$dsn = "DBI:mysql:database=coursera_forum;host=localhost;port=3306";
	}
	
	my $dbh;
	
	if (defined $unicode){
		print "\n connecting to sqlite with unicode";
		$dbh = DBI->connect($dsn,$uname,$pswd,{sqlite_unicode => 1})
						or die "pl says Cannot connect:   $DBI::errstr\n";
	}
	else{
		print "\n connecting to sqlite with no unicode \n $dsn \n $uname \t $pswd";
		$dbh = DBI->connect($dsn,$uname,$pswd)
						or die "pl says Cannot connect:   $DBI::errstr\n";
	}
	return $dbh;
}

sub readThreadSnapshotTable{
	my ($dbh, $courseid) = @_;
	my $query = "select forumid, intervened_thread, snapshot_time, 
						threadid, last_post_time
					from thread_snapshots
					where courseid = '$courseid'";
	my $snapshot = $dbh->selectall_arrayref($query) or die "Model --readThread_snapshots. ";
	return $snapshot;
}

sub getSnapshots{
	my ($dbh, $courseid) = @_;
	my $query = "select intervened_thread, threadid, last_post_time from thread_snapshots 
					where courseid = '$courseid'";
	my $user_snapshot = $dbh->selectall_arrayref($query) or die "Model --getSnapshots. ";
	return $user_snapshot;
}

sub getDocThreadidMap{
	my ($dbh,$course) =@_;
	
	my $query 	= "select docid, id from thread where courseid = '$course'";
	my $map = $dbh->selectall_hashref($query,'id')
							or die "query failed for $course Model --getDocThreadidMap. ";
	
	return $map;
}

sub getOrderedSnapshots{
	my ($dbh, $courseid) = @_;
	my $query 		= "select snapshot_time, threadid, intervened_thread from thread_snapshots 
							where courseid = '$courseid' order by snapshot_time";
	my $user_snapshot = $dbh->selectall_arrayref($query) or die "Model --getOrderedSnapshots. ";
	return $user_snapshot;
}

sub getOrderedInterventions{
	my ($dbh, $courseid) = @_;
	my $query = "select snapshot_time, intervened_thread from thread_snapshots 
					where courseid = '$courseid' order by snapshot_time";
	my $time_stamped_interventions = $dbh->selectall_arrayref($query) or die "Model --getOrderedInterventions. ";
	return $time_stamped_interventions;
}

sub getThreadOccurenceSnapshots{
	my ($dbh, $courseid) = @_;
	# my $query = "select threadid,count(distinct snapshot_time) from thread_snapshots 
					# where courseid = '$courseid' group by threadid";
	my $query	= "select t.docid, count(distinct snapshot_time) 
					from thread_snapshots s, thread t 
					where s.courseid = '$courseid' and s.threadid = t.id 
					and s.courseid = t.courseid group by s.threadid";
	my $user_snapshot = $dbh->selectall_arrayref($query) or die "Model --getThreadOccurenceSnapshots. ";
	return $user_snapshot;
}							

sub getRankOneThread{
	my ($dbh, $courseid, $forumid) = @_;
		"select intervened_thread, max(last_post_time) from thread_snapshots 
			where courseid = '$courseid' and forumid = '$forumid' 
			group by intervened_thread";
}

# sub getPostVote{
	# my ($dbh, $course, $thread, $forum, $post) = @_;
	# my $qry_post = "select votes from post where courseid = $courseid
	# thread_id = $thread and forumid = $forumid and id = $post";
	
	# my $qry_cmnt = "select votes from comment where courseid = $courseid
	# thread_id = $thread and forumid = $forumid and id = $post";
	
	# my $postvote	= $dbh->selectcol_arrayref($qry_post) or die "Model-- getThreadVotes cannot prepare $qry_post";
	# my $cmntvote	= $dbh->selectcol_arrayref($qry_cmnt) or die "Model-- getThreadVotes cannot prepare $qry_cmnt";
	
	# if ( @{$postvote}[0] == 0){
		# if ( @{$cmntvote}[0] == 0){
			# return 0;
		# }
		# else{
			# return @{$cmntvote}[0];
		# }		
	# }
	# else{
		# return @{$postvote}[0];
	# }
# }

sub getThreadVotes{
	my ($dbh, $courses) = @_;
	my $qry_post = "select thread_id, forumid, id, votes from post where courseid = ?";
	my $qry_cmnt = "select thread_id, forumid, id, votes from comment where courseid = ?";
	my $poststh	= $dbh->prepare($qry_post) or die "Model-- getThreadVotes cannot prepare $qry_post";
	my $cmntsth	= $dbh->prepare($qry_cmnt) or die "Model-- getThreadVotes cannot prepare $qry_cmnt";
	my %threads = ();
	
	foreach my $courseid (@$courses){
		$poststh->execute($courseid);
		$cmntsth->execute($courseid);
		
		my $posts = $poststh->fetchall_arrayref();
		foreach my $post (@$posts){
			my $threadid = $post->[0];
			my $forumid	 = $post->[1];
			my $postid	 = $post->[2];
			my $votes	 = $post->[3];
			 
			$threads{$courseid}{$forumid}{$threadid}{$postid}	= $votes;
		}
		
		my $comments  = $cmntsth->fetchall_arrayref();
		foreach my $comment (@$comments){
			my $threadid 	= $comment->[0];
			my $forumid  	= $comment->[1];
			my $commentid	= $comment->[2];
			my $votes		= $comment->[3];
			
			$threads{$courseid}{$forumid}{$threadid}{$commentid} = $votes;
		}
	}
	
	return \%threads;
}

sub getCourses{
	my ($dbh, $dataset, $downloaded) = @_;
	my $query = "select distinct courseid from forum where ";

	if (defined $downloaded){
		$query .= "downloaded = $downloaded";
	}else{
		$query .= "downloaded = 0";
	}
	
	if (defined $dataset){
		$query .= " and dataset = \'$dataset\'";
	}
	
	my $courses = $dbh->selectcol_arrayref($query) or die "$DBI::errstr\n";
	return $courses;
}

sub getforumname{
	my ($dbh, $forumid, $courseid) = @_;
	my $query = "select forumname from forum where id = $forumid and courseid = \'$courseid\'";
	my $forumname = $dbh->selectrow_arrayref($query) or die "$DBI::errstr\n";
	return $forumname;
}

sub getSubForums{
	my ($dbh,$courses,$forumid,$forumname,$dataset, $recrawl) = @_;
	my $query = "select id,courseid,forumname from forum where downloaded ";
	if(defined $recrawl){
		$query .= " = $recrawl";
	}
	else{
		$query .= " is null";
	}
	
	if(defined $courses){
		$query = appendListtoQuery($query,$courses,'courseid',"and");
	}
	if(defined $forumid){
		$query .= " and id = $forumid";
	}
	if(defined $forumname){
		$query .= " and forumname = \'$forumname\'";
	}	
	print "\nExecuting $query";
	my $subforums = $dbh->selectall_arrayref($query) or die "$DBI::errstr\n";
	return $subforums;
}

sub appendListtoQuery{
	my($query, $list, $predicate, $clause) = @_;
	if(defined $list){
		$query	.= " $clause $predicate in ( ";
		foreach my $item (@$list){
			$query .= " \'$item\',";
		}
		$query  =~ s/\,$//;
		$query .= " ) ";
	}
	return $query;
}

sub getNumValidThreads{
	my($dbh,$courses) = @_;
	if (!defined $courses){
		die "\n Model-getNumValidThreads: no input corpus to count on.";
	}
	my %number_of_threads = ();
	my $numthreads = 0;
	
	my $qryinst = "select count(1) from (select distinct threadid, courseid from termFreqC14inst) ";
	
	$qryinst = appendListtoQuery($qryinst,$courses, 'courseid ', 'where ');
	$numthreads += @{$dbh->selectcol_arrayref($qryinst)}[0];
	#print "\n$qryinst \t $numthreads";
	
	my $qrynoinst = "select count(1) from (select distinct threadid, courseid from termFreqC14noinst)";
	$qrynoinst = appendListtoQuery($qrynoinst,$courses, 'courseid ', 'where');	
	$numthreads += @{$dbh->selectcol_arrayref($qrynoinst)}[0];
	#print "\n$qrynoinst \t $numthreads";
	
	return $numthreads;
}
	
sub getNumThreads{
	my( $dbh,$courses ) = @_;
	
	my %number_of_threads = ();
	my %number_of_interventions = ();
		
	my $forumidsquery = "select courseid, sum(numthreads), sum(numinter) from forum 
							where courseid not in( 'ml' )
							and forumname in ('Errata','Exam','Lecture','Homework') ";
	if(defined $courses){
		$forumidsquery .= "and courseid in ( ";
		foreach my $course (@$courses){
			$forumidsquery .= " \'$course\',";
		}
		$forumidsquery =~ s/\,$//;
		$forumidsquery .= " ) ";
	}					
							
	$forumidsquery .= "group by courseid";
	
	my $forumrows = $dbh->selectall_arrayref($forumidsquery) 
						or die "courses query failed! \t $forumidsquery";
	foreach my $forumrow ( @$forumrows ){
		my $coursecode = @$forumrow[0];
		my $num_threads = @$forumrow[1];
		my $num_inter = @$forumrow[2];
		
		#TODO prepare following query outside the loop
		if(!exists $number_of_threads{$coursecode}){
			$number_of_threads{$coursecode} = $num_threads;
		}
		else{
			$number_of_threads{$coursecode} += $num_threads;
		}
		
		if(!exists $number_of_interventions{$coursecode}){
			$number_of_interventions{$coursecode} = $num_threads;
		}
		else{
			$number_of_interventions{$coursecode} += $num_threads;
		}
	}
	return (\%number_of_threads, \%number_of_interventions);
}

sub getIntructorTAOnlyThreads{
	my ($dbh, $courseid, $forumid) = @_;
	my $query = "select distinct thread_id from post3 where courseid=? ";
	
	if(defined $forumid){
		$query .= " and forumid=? ";
	}
	print "Executing.. $query \n";
	my $sth = $dbh->prepare($query)
					or die "Couldn't prepare statement: " . $dbh->errstr;
	if (defined $forumid){
		$sth->execute($courseid,$forumid)
							or die "Couldn't execute statement: " . $query->errstr;
	}
	else{
		$sth->execute($courseid)
							or die "Couldn't execute statement: " . $query->errstr;
	}
	my $threadids = $sth->fetchall_arrayref();
	
	my $where = "id in ( ";
	foreach my $threadid(@$threadids){
		print "$threadid->[0] \t $courseid \t $forumid \n";
		$where .= "$threadid->[0],";
	}
	$where =~ s/\,$//;
	$where .= ")";
	$threadids = Getthreadids($dbh, $courseid, $forumid, $where);
	return $threadids;
}

sub Getthreadids{
	my ( $dbh, $courseid, $forumid, $where ) = @_;
	my $query = "select id,docid,courseid,inst_replied,title,posted_time, forumid from thread where courseid=? ";
	
	if(!defined $courseid){
		die "Exception: Model-Getthreadids: $courseid not defined \n";
	}
	
	if(defined $forumid){
		$query .= " and forumid=? ";
	}
	if(defined $where){
		$query .= " and ".$where;
	}
	
	#$query .= " order by posted_time asc";
	
	print "\nExecuting.. $query ";
	my $sth = $dbh->prepare($query)
						or die "Couldn't prepare statement: " . $dbh->errstr;
	if (defined $forumid){
		$sth->execute($courseid,$forumid)
							or die "Couldn't execute statement: " . $query->errstr;
	}
	else{
		$sth->execute($courseid)
							or die "Couldn't execute statement: " . $query->errstr;
	}
	my $threadids = $sth->fetchall_arrayref();
	return $threadids;
}

sub getthread{
	my ($dbh,$docid) = @_;
	my $row = $dbh->selectrow_arrayref("select courseid, id, forumid from thread where docid = $docid");
	if (!defined $row){
		die "Exception: Model-getthread: thread $docid not found in thread table";
	}
	my @threadrow = @{$row};
	my $coursecode = $threadrow[0];
	my $threadid= $threadrow[1];
	my $forumid= $threadrow[2];
	return ($threadid,$coursecode,$forumid);
}

sub getThreadtype{
	my ($dbh,$docid) = @_;
	my $query = "select forumname from forum 
				where id = (select forumid from thread where docid = $docid) 
				and courseid = (select courseid from thread where docid = $docid)";
	my $type = @{$dbh->selectcol_arrayref($query)}[0];
	return $type;
}

sub hasInstReplied{
	my($dbh, $docid) = @_;
	my $query = "select inst_replied from thread where docid = $docid";
	my $inst_replied = @{$dbh->selectcol_arrayref($query)}[0];
	return $inst_replied;
}

sub getterms{
	my ($dbh, $threadid, $courseid, $docid) = @_;
	#print "Model.getterms $threadid \t $courseid \n"; exit(0);
	
	my $inst_replied = hasInstReplied($dbh,$docid);
	my $tftable;
	
	if($inst_replied){
		$tftable ='termFreqC14inst';
	}
	else{
		$tftable ='termFreqC14noinst';
	}
	
	my $query = "select termid, term, type, sum(tf) sumtf from $tftable where courseid = \'$courseid\' ";
	
	if(defined $threadid){
		$query .= " and threadid = $threadid ";
	}
	
	$query .=  " group by termid";
	my $hashref =  $dbh->selectall_hashref($query,'termid');
	return $hashref;
}

sub getalltfs{
	my ($dbh, $tftab, $course_samples, $terms, $stem, $length) = @_;
	
	if(!defined $dbh){
		print "\n database handler undefined in getalltfs";
		exit(0);
	}
	
	if(!defined $tftab){
		print "\n tftab undefined in getalltfs";
		exit(0);		
	}
	
	if(!defined $course_samples || (keys %$course_samples == 0)){
		print "\n course_samples undefined or 0 in getalltfs";
		exit(0);		
	}
	
	if(!defined $terms || (keys %$terms == 0)){
		print "\n terms undefined or 0 in getalltfs";
		exit(0);		
	}
	
	my $termTFquery = "select termid, courseid, threadid, tf from $tftab
						where courseid in ( ";

	foreach my $courseid (keys %{$course_samples} ){
		$termTFquery .= "\'$courseid\', ";
	}
	$termTFquery =~ s/,\s?$//;
	$termTFquery .= " )";
	
	if (defined $length){
		$termTFquery .= " and length(term) > $length";
	}
	
	print "\nExecuting... $termTFquery";
	
	my @termTFrows =  @{$dbh->selectall_arrayref($termTFquery)};
	#print "\n Model.pm termtfrows " .(scalar @termTFrows)."\n";
	
	my %termfreq = ();
	foreach my $tfrow (@termTFrows ){
		my $courseid	= $tfrow->[1];
		my $threadid	= $tfrow->[2];

		my $termid		= $tfrow->[0];
		my $tf 			= $tfrow->[3];
		
		if(defined $terms && !exists $terms->{$termid}){
			next;
		}		
		
		if(!exists $termfreq{$courseid}{$threadid}{$termid}){
			$termfreq{$courseid}{$threadid}{$termid} = $tf;
		}
		else{
			$termfreq{$courseid}{$threadid}{$termid} += $tf;
		}
	}
	
	if(keys %termfreq == 0){
		print "Exception: TFs are empty in Model.pm";
		exit(0);
	}
	
	return \%termfreq;
}

sub getallTFsbyPost{
	my ($dbh, $tftab, $course_samples, $terms, $stem, $length) = @_;
	
	if(!defined $dbh){
		print "\n database handler undefined in getalltfs";
		exit(0);
	}
	
	if(!defined $tftab){
		print "\n tftab undefined in getalltfs";
		exit(0);		
	}
	
	if(!defined $course_samples || (keys %$course_samples == 0)){
		print "\n course_samples undefined or 0 in getalltfs";
		exit(0);		
	}
	
	if(!defined $terms || (keys %$terms == 0)){
		print "\n terms undefined or 0 in getalltfs";
		exit(0);		
	}
	
	my $termTFquery = "select termid, courseid, threadid, tf, postid, commentid, ispost from $tftab
						where courseid in ( ";

	foreach my $courseid (keys %{$course_samples} ){
		$termTFquery .= "\'$courseid\', ";
	}
	$termTFquery =~ s/,\s?$//;
	$termTFquery .= " )";
	
	if (defined $length){
		$termTFquery .= " and length(term) > $length";
	}
	
	print "\nExecuting... $termTFquery";
	
	my @termTFrows =  @{$dbh->selectall_arrayref($termTFquery)};
	#print "\n Model.pm termtfrows " .(scalar @termTFrows)."\n";
	
	my %termfreq = ();
	foreach my $tfrow (@termTFrows ){
		my $termid = $tfrow->[0];
		my $courseid = $tfrow->[1];
		my $threadid = $tfrow->[2];

		my $tf = $tfrow->[3];
		my $postid = $tfrow->[4];
		my $commentid = $tfrow->[5];
		my $ispost = $tfrow->[6];
		
		if ($ispost eq 0){
			$postid =	$commentid;
		}
		
		if(defined $terms && !exists $terms->{$termid}){
			next;
		}		
		
		if(!exists $termfreq{$courseid}{$threadid}{$postid}{$termid}){
			$termfreq{$courseid}{$threadid}{$postid}{$termid} = $tf;
		}
		else{
			die "Exception: Duplicate term record for term $termid \t $threadid \t $courseid ";
		}
	}
	
	if(keys %termfreq == 0){
		print "Exception: Model.pm .. getallTFsbyPost.. TFs are empty";
		exit(0);
	}
	
	return \%termfreq;
}

sub gettermCourse{
	my ($dbh) = @_;

	my $query	 = "select distinct termid, courseid from termIDF ";
	print "\n Executing $query...";
	my %terms_per_course = %{$dbh->selectall_hashref($query,'termid')};
	return \%terms_per_course;
}

sub getCoursewisetermIDF{
	my ($dbh, $freqcutoff, $stem, $courses, $normalize) = @_;
	
	if(!defined $courses){
		print "Exception: undef $courses in getCoursewisetermIDF in Model.pm";
		exit(0);
	}
	
	my $terms ;
	my $term_course ;
	foreach my $course (@$courses){
		my $termIDFquery	 = "select termid, term, df, courseid from termIDF ";
		$termIDFquery .= " where courseid = \'$course\'";
		if(defined $freqcutoff){
			$termIDFquery .= "  and df > $freqcutoff ";
		}
		my %terms_per_course = %{$dbh->selectall_hashref($termIDFquery,'termid')};
		($terms,$term_course)	= Model::updateHash(\%terms_per_course,$terms,$term_course);
		print "\n Executing $termIDFquery...";
	}

	# print "\n-- $terms->{365}{'termid'}";
	# print "\t $terms->{365}{'courseid'}";
	# print "\t $terms->{365}{'term'}";
	# print "\n -- $terms->{'casebasedbiostat-002'}{365}{'formula'}";
	# print "\n $terms->{'bioelectricity-002'}{365}{'formula'}";
	
	return ($terms,$term_course);
}

sub getForumname{
	my ($dbh,$forumid,$courseid) = @_;
	my $forumname = @{$dbh->selectcol_arrayref("select forumname from forum where id = $forumid and courseid = \'$courseid\'")}[0];
	return $forumname;
}

sub getalltermIDF{
	my ($dbh, $freqcutoff, $stem, $courses, $normalize) = @_;
	
	if(!defined $normalize){
		die "Exception: getalltermIDF: normalize not defined \n";
	}

	# if(!defined $courses){
		# die "Exception: getalltermIDF: courses not defined \n";
	# }
	
	my $termIDFquery;
	
	if($normalize){
		$termIDFquery = "select termid,term,idf,courseid from termIDF ";
		$termIDFquery .= "where courseid = ?";
		if(defined $freqcutoff){
			$termIDFquery .= "and df > $freqcutoff ";
		}
	}
	else{
		$termIDFquery	 = "select termid,term,sum(df) sumdf from termIDF ";
		
		if(defined $courses){
			$termIDFquery	.= "where courseid in ( ";
			foreach my $course (@$courses){
				$termIDFquery .= " \'$course\',";
			}
			$termIDFquery  =~ s/\,$//;
			$termIDFquery .= " ) ";
		}
		
		$termIDFquery .= "group by termid ";
		
		if(defined $freqcutoff){
			$termIDFquery .= "having sumdf > $freqcutoff ";
		}
	}
	
	print "\nExecuting IDFquery... $termIDFquery\n";
	
	my %terms = ();
	if($normalize){
		my $termsth = $dbh->prepare($termIDFquery) or die"Prepare failed\n$termIDFquery";
		foreach my $courseid (@$courses){
			$termsth->execute($courseid) or die "Execute failed \n $termIDFquery";
			my $termrows = $dbh->fetchall_arrayref();
			if (scalar @$termrows == 0){
				die "Exception: termIDFs are empty for $courseid! Normalize: $normalize. 
										Check the tables and the query!\n";
			}
			foreach my $termrow (\@$termrows){
				my $termid		= $termrow->[0];
				#my $term		= $termrow->[1];
				my $idf			= $termrow->[2];
				my $courseid	= $termrow->[3];	
				
				$terms{$courseid}{$termid} = $idf;
			}
		}
	}
	else{
		  %terms = %{$dbh->selectall_hashref($termIDFquery,'termid')};
	}
	return \%terms;
}

sub gettermIDF{
	my ($dbh,$termid,$stem) = @_;	
	my $query = "select idf from termIDF where termid = $termid ";
	# if(!$stem){
		# $query .= "and stem = $stem";
	# }
	return @{$dbh->selectcol_arrayref($query)}[0];
}

sub findMaxPostTimeInterval{
	my ($dbh, $threads) = @_;
	my $maxpost = $dbh->prepare("select max(post_time) from post where thread_id = ? and courseid=?");
	my $minpost = $dbh->prepare("select min(post_time) from post where thread_id = ? and courseid=?");
	my $mincom = $dbh->prepare("select max(post_time) from comment where thread_id = ? and courseid=?");
	my $max_diff = 0;
		
	foreach(@$threads){
		my $threadid = $_->[0];
		my $courseid = $_->[1];
		$maxpost->execute($threadid,$courseid);
		$minpost->execute($threadid,$courseid);
		$mincom->execute($threadid,$courseid);
		my @maxpostarr = @{$maxpost->fetchrow_arrayref()}[0];
		my @minpostarr = @{$minpost->fetchrow_arrayref()}[0];
		my @maxcomarr = @{$mincom->fetchrow_arrayref()}[0];
		my $maxposttime = $maxpostarr[0];
		my $minposttime = $minpostarr[0];
		my $maxcomtime = $maxcomarr[0];
		
		if (!defined  $minposttime || !defined  $maxposttime) {	next; }
		
		my $maxtime = $maxposttime;
		if (defined $maxcomtime){	$maxtime = ($maxcomtime > $maxtime)? $maxcomtime:$maxtime	};
		
		my $diff = $maxtime - $minposttime;
		$max_diff = ($diff > $max_diff) ? $diff : $max_diff;
	}

	print $max_diff;
	return $max_diff;
}

sub updateHash{
	my ($terms_per_course,$terms,$term_course_count) = @_;
	
	foreach my $termid (keys %$terms_per_course){
		my $courseid 	= $terms_per_course->{$termid}{'courseid'};
		my $term 		= $terms_per_course->{$termid}{'term'};	
		my $df			= $terms_per_course->{$termid}{'df'};
		$terms->{$courseid}{$termid}{$term} = $df;
		$term_course_count->{$termid}{$courseid} = 1;
	}
	return ($terms, $term_course_count);
}
1;