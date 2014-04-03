#!/usr/bin/env bats

@test "nellie running" {
  pgrep -f java.*nellie
}

@test "nellie connect test" {
  skip
  grep "Test connect called" /var/log/nellie.log
}
