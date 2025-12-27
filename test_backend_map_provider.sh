#!/bin/bash

# Test Backend Map Provider Setting
# This script checks what map provider your backend is configured to use

echo "🔍 Testing Sokofiti Backend Map Provider Setting..."
echo ""

# Test 1: Get system settings
echo "📡 Test 1: Fetching system settings..."
SETTINGS_RESPONSE=$(curl -s "https://admin.sokofiti.ke/api/get-system-settings")

# Extract map_provider value
MAP_PROVIDER=$(echo "$SETTINGS_RESPONSE" | grep -o '"map_provider":"[^"]*"' | cut -d'"' -f4)

echo "Map Provider: $MAP_PROVIDER"
echo ""

# Check if it's correct
if [ "$MAP_PROVIDER" = "free_api" ]; then
    echo "❌ PROBLEM FOUND!"
    echo "   Backend is set to 'free_api' - this won't use Google Places API"
    echo ""
    echo "✅ FIX: Change backend setting to 'google' or 'places_api'"
    echo "   Go to: https://admin.sokofiti.ke/admin → Settings → Map Provider"
elif [ -z "$MAP_PROVIDER" ]; then
    echo "⚠️  WARNING: Map provider setting not found or empty"
    echo "   This might cause issues with location search"
else
    echo "✅ Map Provider is set to: '$MAP_PROVIDER'"
    echo "   This should use Google Places API"
fi

echo ""
echo "---"
echo ""

# Test 2: Test location search
echo "📡 Test 2: Testing location search for 'Mombasa'..."
SEARCH_RESPONSE=$(curl -s "https://admin.sokofiti.ke/api/get-location?search=Mombasa&lang=EN")

# Check if response contains "predictions" (Places API) or just "data" (free API)
if echo "$SEARCH_RESPONSE" | grep -q '"predictions"'; then
    echo "✅ SUCCESS! Backend is using Google Places API"
    echo ""
    echo "Sample response:"
    echo "$SEARCH_RESPONSE" | head -c 200
    echo "..."
elif echo "$SEARCH_RESPONSE" | grep -q '"data"'; then
    echo "❌ Backend is using FREE API (not Places API)"
    echo ""
    echo "Sample response:"
    echo "$SEARCH_RESPONSE" | head -c 200
    echo "..."
    echo ""
    echo "✅ FIX: Change backend map_provider setting to 'google'"
else
    echo "⚠️  Unexpected response format"
    echo "$SEARCH_RESPONSE" | head -c 300
fi

echo ""
echo "---"
echo ""
echo "📋 Summary:"
echo "1. Check the Map Provider value above"
echo "2. If it's 'free_api', change it in the backend admin panel"
echo "3. If search response doesn't show 'predictions', Places API is not active"
echo ""
echo "For more details, see: LOCATION_SEARCH_PLACES_API_ISSUE.md"

