#!/bin/bash
  if echo 'db.stats().ok' | mongosh --quiet --norc --disableLogging; then
    exit 0
  fi
  exit 1