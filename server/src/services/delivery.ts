// ── Distance-based delivery engine ──────────────────────────────────────────
// All delivery pricing is configured by the admin and computed here so the
// checkout quote and the authoritative order total always use the same rules.
// Settings are kept in memory (reset on restart) alongside the other store
// settings; swap for a DB table when persistence is needed.

export interface DeliverySettings {
  enabled: boolean;        // master switch for distance-based pricing
  shopName: string;        // origin store name
  shopAddress: string;     // human-readable origin address
  shopLat: number;         // origin latitude
  shopLng: number;         // origin longitude
  freeRadiusKm: number;    // deliveries within this radius are free
  baseFee: number;         // flat handling fee applied beyond the free radius
  perKmFee: number;        // charge per km beyond the free radius
  maxRadiusKm: number;     // beyond this, own delivery is not offered
  freeOrderValue: number;  // orders at/above this subtotal ship free
  thirdPartyEnabled: boolean; // offer a partner courier beyond maxRadiusKm
  thirdPartyName: string;  // partner courier label
  thirdPartyFee: number;   // flat partner courier fee
  expressSurcharge: number; // flat express-delivery premium
  currency: string;        // display currency symbol
}

export const deliverySettings: DeliverySettings = {
  enabled: true,
  shopName: 'ToolsHub Store',
  shopAddress: 'Industrial Area, Mumbai 400001, India',
  shopLat: 19.076,
  shopLng: 72.8777,
  freeRadiusKm: 5,
  baseFee: 40,
  perKmFee: 8,
  maxRadiusKm: 30,
  freeOrderValue: 4999,
  thirdPartyEnabled: true,
  thirdPartyName: 'Partner Courier',
  thirdPartyFee: 149,
  expressSurcharge: 199,
  currency: '₹',
};

const NUMERIC_KEYS: (keyof DeliverySettings)[] = [
  'shopLat', 'shopLng', 'freeRadiusKm', 'baseFee', 'perKmFee',
  'maxRadiusKm', 'freeOrderValue', 'thirdPartyFee', 'expressSurcharge',
];
const BOOL_KEYS: (keyof DeliverySettings)[] = ['enabled', 'thirdPartyEnabled'];
const STRING_KEYS: (keyof DeliverySettings)[] = ['shopName', 'shopAddress', 'thirdPartyName', 'currency'];

/** Apply a partial, untrusted settings patch with per-field coercion. */
export function updateDeliverySettings(patch: Record<string, unknown>): DeliverySettings {
  for (const key of NUMERIC_KEYS) {
    if (patch[key] !== undefined) {
      const n = Number(patch[key]);
      if (Number.isFinite(n) && n >= 0) (deliverySettings[key] as number) = n;
    }
  }
  for (const key of BOOL_KEYS) {
    if (patch[key] !== undefined) {
      (deliverySettings[key] as boolean) = patch[key] === true || patch[key] === 'true';
    }
  }
  for (const key of STRING_KEYS) {
    if (typeof patch[key] === 'string') (deliverySettings[key] as string) = patch[key] as string;
  }
  return deliverySettings;
}

/** Great-circle distance between two lat/lng points, in kilometers. */
export function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371; // Earth radius (km)
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(a)));
}

// Small in-memory cache so repeated quotes for the same address don't hammer
// the geocoding provider (Nominatim asks for <= 1 req/sec).
const geocodeCache = new Map<string, { lat: number; lng: number } | null>();

/** Forward-geocode a free-text address into coordinates via Nominatim. */
export async function forwardGeocode(query: string): Promise<{ lat: number; lng: number } | null> {
  const q = query.trim();
  if (!q) return null;
  if (geocodeCache.has(q)) return geocodeCache.get(q)!;
  try {
    const url =
      `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(q)}` +
      `&format=json&limit=1&addressdetails=0`;
    const r = await fetch(url, {
      headers: { 'User-Agent': 'ToolsHub/1.0 (store delivery quote)' },
    });
    if (!r.ok) { geocodeCache.set(q, null); return null; }
    const data: any = await r.json();
    if (!Array.isArray(data) || data.length === 0) { geocodeCache.set(q, null); return null; }
    const hit = { lat: parseFloat(data[0].lat), lng: parseFloat(data[0].lon) };
    const ok = Number.isFinite(hit.lat) && Number.isFinite(hit.lng) ? hit : null;
    geocodeCache.set(q, ok);
    return ok;
  } catch {
    return null;
  }
}

export interface DeliveryQuote {
  deliverable: boolean;      // false => cannot deliver to this address
  mode: 'free-order' | 'own' | 'thirdparty' | 'flat' | 'unavailable';
  distanceKm: number | null; // null when distance couldn't be resolved
  deliveryFee: number;       // STANDARD (location-based) fee, before express
  free: boolean;             // whether the standard fee is 0
  label: string;             // short human-readable explanation
  expressSurcharge: number;  // flat express premium (from settings)
  freeOrderValue: number;    // free-shipping order threshold (from settings)
  currency: string;
}

/**
 * Compute the STANDARD (location-based) delivery quote for a destination.
 * Express is a flat premium applied by the caller, not included in deliveryFee.
 */
export async function computeDelivery(opts: {
  subtotal: number;
  destLat?: number;
  destLng?: number;
  address?: string;
}): Promise<DeliveryQuote> {
  const s = deliverySettings;
  const base = {
    expressSurcharge: s.expressSurcharge,
    freeOrderValue: s.freeOrderValue,
    currency: s.currency,
  };

  // 1. Order-value free shipping wins regardless of distance.
  if (opts.subtotal >= s.freeOrderValue) {
    return {
      deliverable: true, mode: 'free-order', distanceKm: null, deliveryFee: 0,
      free: true, label: `Free delivery on orders over ${s.currency}${s.freeOrderValue}`, ...base,
    };
  }

  // 2. Distance pricing disabled → flat handling fee.
  if (!s.enabled) {
    return {
      deliverable: true, mode: 'flat', distanceKm: null, deliveryFee: s.baseFee,
      free: false, label: 'Standard delivery', ...base,
    };
  }

  // 3. Resolve the destination coordinates.
  let coords: { lat: number; lng: number } | null = null;
  if (Number.isFinite(opts.destLat) && Number.isFinite(opts.destLng)) {
    coords = { lat: opts.destLat as number, lng: opts.destLng as number };
  } else if (opts.address) {
    coords = await forwardGeocode(opts.address);
  }
  if (!coords) {
    return {
      deliverable: true, mode: 'flat', distanceKm: null, deliveryFee: s.baseFee,
      free: false, label: 'Standard delivery', ...base,
    };
  }

  // 4. Distance-tiered pricing.
  const d = haversineKm(s.shopLat, s.shopLng, coords.lat, coords.lng);
  const dr = Math.round(d * 10) / 10;

  if (d <= s.freeRadiusKm) {
    return {
      deliverable: true, mode: 'own', distanceKm: dr, deliveryFee: 0, free: true,
      label: `Free delivery · within ${s.freeRadiusKm} km`, ...base,
    };
  }
  if (d <= s.maxRadiusKm) {
    const fee = Math.round(s.baseFee + Math.ceil(d - s.freeRadiusKm) * s.perKmFee);
    return {
      deliverable: true, mode: 'own', distanceKm: dr, deliveryFee: fee, free: false,
      label: `${dr} km away`, ...base,
    };
  }
  if (s.thirdPartyEnabled) {
    return {
      deliverable: true, mode: 'thirdparty', distanceKm: dr, deliveryFee: s.thirdPartyFee,
      free: false, label: `${s.thirdPartyName} · ${dr} km`, ...base,
    };
  }
  return {
    deliverable: false, mode: 'unavailable', distanceKm: dr, deliveryFee: 0, free: false,
    label: `Delivery unavailable beyond ${s.maxRadiusKm} km`, ...base,
  };
}
