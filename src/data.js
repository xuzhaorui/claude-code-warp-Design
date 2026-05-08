export const plans = [
  {
    id: 'week',
    label: '1 Week',
    price: 8.99,
    perWeek: 8.99,
    badge: null,
    popular: false,
  },
  {
    id: 'month',
    label: '1 Month',
    price: 24.99,
    perWeek: 5.77,
    badge: 'Most Popular',
    popular: true,
  },
  {
    id: 'lifetime',
    label: 'Lifetime',
    price: 149.99,
    perWeek: null,
    badge: 'Save 70%',
    popular: false,
  },
]

export const features = [
  { name: 'See who liked you', basic: false, premium: true },
  { name: 'Unlimited swipes', basic: false, premium: true },
  { name: 'Unlimited backtrack', basic: false, premium: true },
  { name: 'Advanced filters', basic: false, premium: true },
  { name: 'Incognito mode', basic: false, premium: true },
  { name: 'See who viewed your profile', basic: false, premium: true },
  { name: 'Travel mode (change location)', basic: false, premium: true },
  { name: 'Extend matches 24h', basic: false, premium: true },
]
