# E-commerce: product list, filters and a shared cart

Built from `01-minimal`. API: `https://dummyjson.com/products`, `/products/categories`, `/products/category/{slug}`, `/products/{id}`.

## Why this problem
"Small e-commerce app with data synced across screens" is the most repeated mobile machine-coding prompt in Indian product companies:
- **PhonePe** Android, Jul 2025 (lets-code.co.in): e-commerce app with data kept in sync across screens, 90 minutes.
- **Nykaa** SDE-II Android, Aug 2026 (LeetCode Discuss, first-hand): MVVM screen design, StateFlow vs SharedFlow, then design for cart, filters and real-time stock.
- **PrepFlutter** Machine Coding track lists "Cart screen" and "Add-to-cart items don't refresh after tapping add" as practice problems.

These are Android/generic reports; the Flutter version below is my implementation of the same requirements.

## What is built (aim for 90 minutes)
- **Products grid:** loading / error + Retry / empty; responsive column count (`LayoutBuilder`); category chips, an in-stock filter and a sort menu.
- **Detail:** product passed via go_router `extra`, fetch-by-id fallback for deep links.
- **Cart (app-wide `CartCubit` above the router):** add, stepper (− qty +), swipe to delete, capped at stock with a snackbar, total, checkout clears it, persisted across restarts. The badge on every app bar updates live.

## Points to make in the round
| Topic | What the code does |
|---|---|
| **Shared state across screens** | One `CartCubit` provided above `MaterialApp.router`. Every screen reads the same instance, so list, detail and cart can never disagree. (The bug in "items don't refresh after tapping add" is usually a cubit created per screen.) |
| **Minimal rebuilds** | `context.select` for the badge count and for each product's quantity: tapping Add rebuilds that card's control and the badge, not the grid. |
| **Money** | Integer cents (`toCents`, `formatCents`). `0.1 + 0.2 != 0.3` in doubles; a total must be exact. |
| **Stale responses** | Fast chip taps: `ProductsCubit` tags each request and drops responses for an older category (tested with out-of-order completers). |
| **Derived data** | Sorting and filtering happen once in the `ProductsState` constructor (`visible`), never in `build`. |
| **Images** | `cacheWidth` decodes thumbnails at display size, and `errorBuilder` shows a placeholder. Mention `cached_network_image` for disk caching. |
| **Stock** | Client caps at `stock` for UX; the server must still validate at checkout. Real-time stock: WebSocket/SSE pushes `stock` updates, and the cart corrects quantities and tells the user. |

## Tests (17)
Cart (6): quantity merge with an exact total, stock cap, out of stock, decrement/remove keeps order, restore after restart, money formatting. Products (4): load, sort/filter, stale category response ignored, failure → retry. Flow widget test (1): add → stepper → badge → cart total → checkout empties. Core (5) and app shell (1).

## Follow-ups to rehearse
- **LLD:** `Product`, `CartItem`, `CartState`, `CartCubit`, `CartStorage` (strategy for persistence), `ShopRepository`. Where would coupons go? (A `PricingPolicy` that turns the cart into a price breakdown.)
- **HLD:** cart service keyed by user, guest cart merged at login, idempotent `POST /orders` with an idempotency key, inventory reservation with a TTL.
- **Offline:** queue cart mutations and replay them; server is the source of truth for price and stock at checkout.
