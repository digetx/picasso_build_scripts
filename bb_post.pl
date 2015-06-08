#!/usr/bin/perl -w

use File::Basename;
use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Cookies;
use utf8;
use strict;

use Env qw(BUSR BPWD);

binmode(STDOUT, ':utf8');
binmode(STDIN, ':utf8');

my $ua = LWP::UserAgent->new(requests_redirectable => [ 'POST', 'GET' ]);
$ua->conn_cache(LWP::ConnCache->new());
$ua->cookie_jar(HTTP::Cookies->new());

sub get_token {
	my ($url) = shift;

	my $res = $ua->get("$url");

	my ($token)= ($res->decoded_content =~ /name='csrfmiddlewaretoken' value='(.+?)'/);
	die if (! defined $token);

	return $token;
}

sub bb_login {
	my $token = get_token('https://bitbucket.org/account/signin/');

	my $req = HTTP::Request->new(POST => 'https://bitbucket.org/account/signin/');
	$req->referer('https://bitbucket.org/account/signin/');
	$req->content_type('application/x-www-form-urlencoded');
	$req->content("username=$BUSR&password=$BPWD&csrfmiddlewaretoken=$token&submit=");
	my $res = $ua->request($req);

	die 'Bitbucket login failed' if ($res->decoded_content !~ /log-out-link/);
}

sub post {
	my $proj = $ARGV[0];
	my $file_path = $ARGV[1];
	my $file_name = basename $file_path;
	my $retries = 3;

RETRY:
	my $token = get_token("https://bitbucket.org/$BUSR/$proj/downloads");

	my $res = $ua->post("https://bitbucket.org/$BUSR/$proj/downloads",
		[ 'csrfmiddlewaretoken'	=> "$token",
		  'token'		=> "",
		  'files'		=> ["$file_path"],
		],
		Content_Type => 'form-data',
		referer => "https://bitbucket.org/$BUSR/$proj/downloads",
	);

	return if ($res->decoded_content =~ /$file_name/);

	sleep 3;

	goto RETRY if ($retries--);

	die 'Bitbucket posting failed';
}

bb_login();
post();
