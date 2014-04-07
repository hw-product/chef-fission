#!/usr/bin/env bats

@test "nellie worker running" {
  # This command is supposed to wait for the first positive log entry, but not too long.
  # The idea is to give the JVM some time to start.
  # However, this next line seems to hang `kitchen verify`:

  # timeout 30s grep -q 'Adding callback class (Fission::Callbacks::Webhook) under supervision.' <(tail -f /var/log/nellie/current)

  # Instead we're waiting the whole timeout:

  sleep 30
  grep 'Adding callback class (Fission::Callbacks::Webhook) under supervision.' /var/log/nellie/current 
}