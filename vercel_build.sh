#!/bin/bash
echo "window.GOOGLE_MAPS_API_KEY = \"$GOOGLE_MAPS_API_KEY\";" > web/env.js
flutter build web
