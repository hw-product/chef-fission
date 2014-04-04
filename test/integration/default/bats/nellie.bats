#!/usr/bin/env bats

@test "nellie running" {
  pgrep -f java.*nellie
}
