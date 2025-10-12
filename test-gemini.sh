#!/bin/bash
curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=AIzaSyD4yfmIfdtBxCEkEAIkIyHxHA33jILD6cY" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"Say hello"}]}]}'
