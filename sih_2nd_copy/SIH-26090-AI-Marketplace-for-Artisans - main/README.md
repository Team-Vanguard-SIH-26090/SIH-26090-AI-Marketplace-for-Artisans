# SIH-26090-AI-Marketplace-for-Artisans

## Included e-commerce updates

- Buyer marketplace with active-product search.
- Cart, server-calculated totals, Cash on Delivery checkout, and order history.
- Password visibility toggles on login and signup.
- Email OTP password reset endpoints.
- Required delivery address during signup and editable profile information.
- Full-size product image preview.
- AI-generated material, craft technique, English/regional bilingual listing review, and price breakdown.
- Marketplace hero carousel, category filters, artisan badges, and material chips.
- Buyer order tracking, artisan sales analytics, order-status management, and notification center.
- Standard English, Hindi, Marathi, Tamil, and Bengali locale switching.
- Native camera/microphone capture with image and audio preview.
- Removed the duplicate Auto Catalog dashboard tile; Auto Catalog remains available from Image Studio.
- My Store now loads the actual listed-product count and no longer shows views.

## Backend configuration

Copy `backend/.env.example` to `backend/.env`. `MONGO_URI` is required. To send password-reset OTPs by email, configure the SMTP variables. When SMTP is not configured, the backend prints the OTP to its server log for local development only.

New endpoints:

- `POST /auth/forgot-password`
- `POST /auth/reset-password`
- `GET /artisans/{artisan_id}`
- `PUT /artisans/{artisan_id}`
- `GET /products?active_only=true&search=...`
- `POST /orders`
- `GET /orders?buyer_id=...`
- `GET /artisan/orders?artisan_id=...`
- `PATCH /orders/{order_id}/item-status`
- `GET /artisan/analytics?artisan_id=...`
- `GET /notifications?user_id=...`
- `PATCH /notifications/{notification_id}/read?user_id=...`

The MongoDB database now uses `orders`, `password_resets`, and `notifications` collections in addition to the existing `artisans` and `products` collections. Existing collections do not need a migration; new fields are added when users update their profile or place orders.