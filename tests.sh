#!/usr/bin/env bash
. ./site.sh

ip4='1.2.3.4'
ip6='::1234:5678'

test_is_ip4() {
	is_ip4 $ip4 && result=T || result=F
	assertEquals T $result
}

test_not_ip4() {
	is_ip4 $ip6 && result=T || result=F
	assertEquals F $result
}

test_is_ip6() {
	is_ip6 $ip6 && result=T || result=F
	assertEquals T $result
}

test_not_ip6() {
	is_ip6 $ip4 && result=T || result=F
	assertEquals F $result
}

phplist=(7.0 7.1 7.2 7.3 7.4 8.0)
match=0
matchlist=()

test_searcharray() {
	searcharray 7.2 phplist && result=T || result=F
	assertEquals T $result
}

test_searcharray_index() {
	searcharray 7.2 phplist if match
	assertEquals 2 $match
}

test_searcharray_reg_multi() {
	searcharray 0 phplist rm matchlist
	assertEquals 2 ${#matchlist[@]}
}

. ../shunit2/shunit2
