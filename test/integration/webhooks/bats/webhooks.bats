#!/usr/bin/env bats

@test "webhook generated" {
  skip
  UUID=uuidgen

  curl \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -X POST \
      -d "{\"uuid\": \"$UUID\", \"ref\": \"refs/heads\"}" \
      http://172.16.162.221:8000/github-commit/push


  # emulating what i think should happen first
  # which is fission posting a webhook about a build
  curl \
      --user name:password \
      --insecure \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -X POST \
      -d "{\"uuid\": \"$UUID\"}" \
      https://requestb.in/1jmufnw1

  # did it post?
  curl --insecure https://requestb.in/1jmufnw1?inspect | grep $UUID
}
