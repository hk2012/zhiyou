from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class DeviceType(str, Enum):
    smart_float = "smart_float"
    smart_tackle_box = "smart_tackle_box"
    smart_platform = "smart_platform"
    smart_umbrella = "smart_umbrella"
    fish_finder = "fish_finder"
    night_light = "night_light"
    hub = "hub"
    sensor = "sensor"
    other = "other"


class DeviceStatus(str, Enum):
    online = "online"
    standby = "standby"
    offline = "offline"
    abnormal = "abnormal"
    unbound = "unbound"


class AlertSeverity(str, Enum):
    info = "info"
    warning = "warning"
    critical = "critical"


class TelemetrySnapshot(BaseModel):
    metric_key: str
    label: str
    value: str
    unit: str = ""
    numeric_value: Optional[float] = None
    quality: str = "normal"
    observed_at: Optional[datetime] = None


class DeviceAlert(BaseModel):
    id: str
    device_id: str
    severity: AlertSeverity = AlertSeverity.info
    title: str
    message: str
    action_label: str = ""
    resolved: bool = False
    created_at: Optional[datetime] = None


class DeviceContract(BaseModel):
    id: str
    name: str
    type: DeviceType
    status: DeviceStatus
    scene_role: str
    battery_level: int = Field(ge=0, le=100)
    signal_level: int = Field(ge=0, le=100)
    telemetry: list[TelemetrySnapshot] = Field(default_factory=list)
    firmware_version: str = ""
    bound_at: Optional[datetime] = None
    last_seen_at: Optional[datetime] = None
    alerts: list[DeviceAlert] = Field(default_factory=list)


class DeviceSummary(BaseModel):
    total: int = 0
    online: int = 0
    offline: int = 0
    low_battery: int = 0
    abnormal: int = 0
    last_sync_at: Optional[datetime] = None


class VenueStatus(str, Enum):
    open = "open"
    paused = "paused"
    full = "full"
    closed = "closed"


class SlotStatus(str, Enum):
    available = "available"
    few = "few"
    full = "full"


class BookingStatus(str, Enum):
    pending = "pending"
    confirmed = "confirmed"
    cancelled = "cancelled"
    completed = "completed"
    failed = "failed"


class VenueSlot(BaseModel):
    id: str
    venue_id: str
    label: str
    time_range: str
    price: int = 0
    member_price: int = 0
    left_seats: int = 0
    status: SlotStatus = SlotStatus.available


class VenuePackage(BaseModel):
    id: str
    venue_id: str
    title: str
    description: str = ""
    price: int = 0
    member_price: int = 0
    includes: list[str] = Field(default_factory=list)


class VenueReview(BaseModel):
    id: str
    venue_id: str
    user_name: str
    rating: float = Field(ge=0, le=5)
    content: str
    tags: list[str] = Field(default_factory=list)


class VenueContract(BaseModel):
    id: str
    name: str
    area: str
    address: str
    status: VenueStatus
    distance_km: float = 0
    rating: float = Field(default=0, ge=0, le=5)
    price_from: int = 0
    member_price_from: int = 0
    today_index: int = Field(default=0, ge=0, le=100)
    fish_species: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)
    supports_booking: bool = False
    supports_night_fishing: bool = False
    supports_smart_device: bool = False
    summary: str = ""
    open_hours: str = ""
    facilities: list[str] = Field(default_factory=list)
    recommended_device_types: list[DeviceType] = Field(default_factory=list)
    packages: list[VenuePackage] = Field(default_factory=list)
    slots: list[VenueSlot] = Field(default_factory=list)
    reviews: list[VenueReview] = Field(default_factory=list)


class VenueBooking(BaseModel):
    id: str
    venue_id: str
    slot_id: str
    user_id: str
    status: BookingStatus = BookingStatus.pending
    amount: int = 0
    booking_date: str = ""
    contact_phone: str = ""


class ProductType(str, Enum):
    device = "device"
    accessory = "accessory"
    bait = "bait"
    venue_package = "venue_package"
    membership = "membership"
    service = "service"


class ProductContract(BaseModel):
    id: str
    name: str
    type: ProductType
    category_key: str
    price: int = 0
    member_price: int = 0
    original_price: int = 0
    stock: int = 0
    rating: float = Field(default=0, ge=0, le=5)
    tags: list[str] = Field(default_factory=list)
    scene: str = ""
    description: str = ""
    supports_membership_discount: bool = False
    supports_device_link: bool = False
    compatible_device_types: list[DeviceType] = Field(default_factory=list)


class CartItem(BaseModel):
    id: str
    product_id: str
    quantity: int = Field(default=1, ge=1)
    selected: bool = True
    added_from: str = ""


class OrderStatus(str, Enum):
    pending_payment = "pending_payment"
    pending_shipment = "pending_shipment"
    pending_receipt = "pending_receipt"
    completed = "completed"
    refunded = "refunded"
    cancelled = "cancelled"


class OrderLine(BaseModel):
    product_id: str
    title: str
    quantity: int = Field(default=1, ge=1)
    price: int = 0


class OrderContract(BaseModel):
    id: str
    order_no: str
    status: OrderStatus = OrderStatus.pending_payment
    amount: int = 0
    lines: list[OrderLine] = Field(default_factory=list)
    created_at: Optional[datetime] = None


class CouponContract(BaseModel):
    id: str
    title: str
    description: str = ""
    amount: int = 0
    threshold: int = 0
    scene: str = ""
    scope_product_ids: list[str] = Field(default_factory=list)
    expires_at: str = ""
    member_only: bool = False


class AfterSaleTicket(BaseModel):
    id: str
    order_id: str
    type: str
    status: str
    title: str


class MembershipStatus(str, Enum):
    inactive = "inactive"
    active = "active"
    expired = "expired"


class MembershipContract(BaseModel):
    plan_id: str
    name: str
    status: MembershipStatus = MembershipStatus.inactive
    expire_at: str = ""
    benefits: list[str] = Field(default_factory=list)
    summary: str = ""


class UserAssetSummary(BaseModel):
    user_id: str
    devices: DeviceSummary
    orders_total: int = 0
    active_bookings: int = 0
    fishing_records: int = 0
    available_coupons: int = 0
    points: int = 0
    favorites: int = 0
    membership: MembershipContract


class DomainContractResponse(BaseModel):
    version: str = "2026-06-14.p0"
    device_types: list[DeviceType] = Field(default_factory=lambda: list(DeviceType))
    venue_statuses: list[VenueStatus] = Field(default_factory=lambda: list(VenueStatus))
    product_types: list[ProductType] = Field(default_factory=lambda: list(ProductType))
    order_statuses: list[OrderStatus] = Field(default_factory=lambda: list(OrderStatus))
    membership_statuses: list[MembershipStatus] = Field(
        default_factory=lambda: list(MembershipStatus)
    )
