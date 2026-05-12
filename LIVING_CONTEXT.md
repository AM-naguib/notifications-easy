# Living Context

## Purpose
- This file is the project memory for recurring order-generation decisions.

## Order Generation Rules
- Demo orders should feel similar to real EasyOrders data, but must not copy the exact names shown in screenshots or examples from the user.
- Names should be mixed:
  - some Arabic
  - some English
  - some triple names
- Demo amounts should stay in the range `1339` to `1379`.
- Demo order numbers usually start from a user-chosen starting point such as `668`.
- The backend helper that generates demo batches is `POST /v1/orders/demo`.
- The admin dashboard has a `Generate Demo Orders` form that uses the same backend helper logic.

## Current Backend Behavior
- `POST /v1/orders` creates a single queue item.
- `POST /v1/orders/demo` creates a demo batch with mixed Arabic/English names and bounded amounts.
- `GET /v1/orders/pending` returns pending queue items for the iPhone app with the newest order first.
- `POST /v1/orders/ack` marks fetched items as acknowledged.

## Notes
- If old test orders become noisy, clear the `orders` table on the server before generating a fresh batch.
- Do not assume screenshot examples are the exact seed data to reuse.
- Notification ordering should feel logical to the user: higher/newer order numbers like `#669` should appear before older ones like `#668`.
- To achieve that in iPhone Notification Center, the app should schedule older orders first and newer orders last, because the system places the most recently delivered notification on top.
- On manual fetches, the app should clear old EasyOrders pending and delivered notifications before scheduling a fresh batch, otherwise batches can overlap on-device and make the order look wrong even when the server order is correct.
