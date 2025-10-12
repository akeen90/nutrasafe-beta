#!/bin/bash
curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=AIzaSyD4yfmIfdtBxCEkEAIkIyHxHA33jILD6cY" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"Say hello"}]}]}'
