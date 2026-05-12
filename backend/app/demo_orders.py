from __future__ import annotations

from .schemas import OrderCreate

DEMO_NAME_SEQUENCE = [
    "هشام فوزي سالم",
    "Tamer Nabil",
    "Yahia Essam Hassan",
    "سيف الدين أحمد",
    "Rami Ashraf",
    "باسم ربيع محمود",
    "Khaled Mostafa",
    "مروان طارق",
    "Fady Naguib",
    "يوسف وائل شريف",
    "Adham Raafat",
    "نورهان علي",
    "Hossam Fares",
    "ملك سامح إبراهيم",
    "Mazen Adel",
    "عبدالرحمن رأفت",
    "Salma Hany",
    "عمر بهاء الدين",
    "Karim Youssef",
    "رحمة وليد أحمد",
    "Nour Ashraf Mahmoud",
    "زياد شوقي",
    "Mina Sameh",
    "دينا خالد محمد",
]

DEMO_MIN_AMOUNT = 1339
DEMO_MAX_AMOUNT = 1379
DEMO_DEFAULT_START_ORDER_NUMBER = 668


def build_demo_orders(
    *,
    count: int,
    start_order_number: int = DEMO_DEFAULT_START_ORDER_NUMBER,
) -> list[OrderCreate]:
    safe_count = max(1, min(count, 50))
    safe_start = max(1, start_order_number)
    amount_span = (DEMO_MAX_AMOUNT - DEMO_MIN_AMOUNT) + 1

    orders: list[OrderCreate] = []
    for index in range(safe_count):
        customer_name = DEMO_NAME_SEQUENCE[index % len(DEMO_NAME_SEQUENCE)]
        amount = str(DEMO_MIN_AMOUNT + ((index * 7) % amount_span))
        order_number = str(safe_start + index)
        orders.append(
            OrderCreate(
                customer_name=customer_name,
                amount=amount,
                order_number=order_number,
            )
        )

    return orders
