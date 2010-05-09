package RDF::RDFa::Generator::HTML::Hidden;

use 5.008;
use base qw'RDF::RDFa::Generator::HTML::Head';
use common::sense;
use XML::LibXML qw':all';

sub injection_site
{
	return '//xhtml:body';
}

sub nodes
{
	my ($proto, $model) = @_;
	my $self = (ref $proto) ? $proto : $proto->new;
	
	my $stream = $self->_get_stream($model);
	my @nodes;
	
	my $rootnode = XML::LibXML::Element->new('i');
	$rootnode->setNamespace('http://www.w3.org/1999/xhtml', undef, 1);
	$rootnode->setAttribute('style','display:none');
	
	my $prefixes = {};
	my $subjects = {};
	while (my $st = $stream->next)
	{
		my $s = $st->subject->is_resource ?
			$st->subject->uri :
			('_:'.$st->subject->blank_identifier);
		push @{ $subjects->{$s} }, $st;
	}
	
	foreach my $s (keys %$subjects)
	{
		my $node = $rootnode->addNewChild('http://www.w3.org/1999/xhtml', 'i');
		
		$self->_process_subject($subjects->{$s}->[0], $node, $prefixes);
		
		foreach my $st (@{ $subjects->{$s} })
		{
			my $node2 = $node->addNewChild('http://www.w3.org/1999/xhtml', 'i');
			$self->_process_predicate($st, $node2, $prefixes)
			     ->_process_object($st, $node2, $prefixes);
		}
	}
	
	if ($self->{'version'} == 1.1
	and $self->{'prefix_attr'})
	{
		my $prefix_string = '';
		while (my ($u,$p) = each(%$prefixes))
		{
			$prefix_string .= sprintf("%s: %s ", $p, $u);
		}
		if (length $prefix_string)
		{
			$rootnode->setAttribute('prefix', $prefix_string);
		}
	}
	else
	{
		while (my ($u,$p) = each(%$prefixes))
		{
			$rootnode->setNamespace($u, $p, 0);
		}
	}
	
	push @nodes, $rootnode;
	
	return @nodes if wantarray;
	
	my $nodelist = XML::LibXML::NodeList->new;
	$nodelist->push(@nodes);
	return $nodelist;
}

sub _process_subject
{
	my ($self, $st, $node, $prefixes) = @_;
	
	if (defined $self->{'base'} 
	and $st->subject->is_resource
	and $st->subject->uri eq $self->{'base'})
		{ $node->setAttribute('src', ''); }
	elsif ($st->subject->is_resource) 
		{ $node->setAttribute('src', $st->subject->uri); }
	else
		{ $node->setAttribute('about', '[_:'.$st->subject->blank_identifier.']'); }
	
	return $self;
}

1;
