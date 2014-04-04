#!/usr/bin/env bats

@test "nellie no worker warning" {
  # timeout 180 grep -q 'PATTERN' <(tail -f /var/log/nellie/current)
  run grep 'Callback class (Fission::Callbacks::Webhook) defined no workers. Skipping.' /var/log/nellie/current
  [ "$status" -eq 0 ]
}
