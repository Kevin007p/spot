// Supabase Edge Function: Google Places API Proxy
// This function proxies requests to the Google Places API so the API key
// stays server-side and never ships in the iOS app.
//
// Deploy with: supabase functions deploy google-places-proxy
// Set secret: supabase secrets set GOOGLE_PLACES_API_KEY=your_key_here

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const GOOGLE_API_KEY = Deno.env.get("GOOGLE_PLACES_API_KEY")!;
const GOOGLE_BASE = "https://maps.googleapis.com/maps/api/place";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const path = url.pathname.split("/").pop();

  try {
    switch (path) {
      case "autocomplete": {
        const query = url.searchParams.get("query");
        if (!query) {
          return new Response(JSON.stringify({ error: "query parameter required" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        const googleUrl = `${GOOGLE_BASE}/autocomplete/json?input=${encodeURIComponent(query)}&types=establishment&key=${GOOGLE_API_KEY}`;
        const res = await fetch(googleUrl);
        const data = await res.json();

        const results = (data.predictions || []).map((p: any) => ({
          id: p.place_id,
          name: p.structured_formatting?.main_text || p.description,
          address: p.structured_formatting?.secondary_text || "",
          category: "",
        }));

        return new Response(JSON.stringify(results), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "details": {
        const placeId = url.searchParams.get("place_id");
        if (!placeId) {
          return new Response(JSON.stringify({ error: "place_id parameter required" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        const fields = "place_id,name,formatted_address,geometry,rating,price_level,types";
        const googleUrl = `${GOOGLE_BASE}/details/json?place_id=${placeId}&fields=${fields}&key=${GOOGLE_API_KEY}`;
        const res = await fetch(googleUrl);
        const data = await res.json();
        const r = data.result;

        if (!r) {
          return new Response(JSON.stringify({ error: "Place not found" }), {
            status: 404,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        const result = {
          googlePlaceId: r.place_id,
          name: r.name || "",
          address: r.formatted_address || "",
          lat: r.geometry?.location?.lat || 0,
          lng: r.geometry?.location?.lng || 0,
          rating: r.rating || 0,
          priceLevel: r.price_level || 0,
          types: r.types || [],
          category: mapCategory(r.types || []),
          cuisine: mapCuisine(r.types || []),
        };

        return new Response(JSON.stringify(result), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "search": {
        const query = url.searchParams.get("query");
        if (!query) {
          return new Response(JSON.stringify({ error: "query parameter required" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        const googleUrl = `${GOOGLE_BASE}/textsearch/json?query=${encodeURIComponent(query)}&type=establishment&key=${GOOGLE_API_KEY}`;
        const res = await fetch(googleUrl);
        const data = await res.json();

        const results = (data.results || []).slice(0, 5).map((r: any) => ({
          id: r.place_id,
          name: r.name,
          address: r.formatted_address || "",
          category: mapCategory(r.types || []),
        }));

        return new Response(JSON.stringify(results), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      default:
        return new Response(JSON.stringify({ error: "Unknown endpoint" }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    }
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

function mapCategory(types: string[]): string {
  for (const type of types) {
    if (["restaurant", "meal_delivery", "meal_takeaway"].includes(type)) return "Restaurant";
    if (type === "cafe") return "Cafe";
    if (["bar", "night_club"].includes(type)) return "Bar";
    if (["bakery", "ice_cream_shop"].includes(type)) return "Dessert";
    if (["amusement_park", "bowling_alley", "gym", "movie_theater", "museum", "park", "spa", "stadium", "tourist_attraction", "zoo"].includes(type)) return "Activity";
  }
  return "Other";
}

function mapCuisine(types: string[]): string {
  const cuisineTypes: Record<string, string> = {
    japanese_restaurant: "Japanese",
    chinese_restaurant: "Chinese",
    italian_restaurant: "Italian",
    mexican_restaurant: "Mexican",
    indian_restaurant: "Indian",
    thai_restaurant: "Thai",
    korean_restaurant: "Korean",
    vietnamese_restaurant: "Vietnamese",
    french_restaurant: "French",
    mediterranean_restaurant: "Mediterranean",
    american_restaurant: "American",
    pizza_restaurant: "Pizza",
    seafood_restaurant: "Seafood",
    steak_house: "Steakhouse",
    sushi_restaurant: "Sushi",
    ramen_restaurant: "Ramen",
    hamburger_restaurant: "Burgers",
  };

  for (const type of types) {
    if (cuisineTypes[type]) return cuisineTypes[type];
  }
  return "";
}
