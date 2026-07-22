"""
Small helpers so the Flutter app can send a due date / birth date once at
profile setup, rather than the user manually updating "weeks pregnant" or
"baby age" every time. Call these when building/refreshing a UserProfile.
"""
from datetime import date


def pregnancy_week_from_due_date(due_date: date, today: date | None = None) -> int:
    """Standard pregnancy is ~40 weeks; count backward from the due date."""
    today = today or date.today()
    days_remaining = (due_date - today).days
    weeks_remaining = days_remaining // 7
    return max(1, min(42, 40 - weeks_remaining))


def pregnancy_week_from_lmp(last_menstrual_period: date, today: date | None = None) -> int:
    """Alternative: count forward from last menstrual period (more common clinically)."""
    today = today or date.today()
    days_elapsed = (today - last_menstrual_period).days
    return max(1, min(42, days_elapsed // 7))


def baby_age_months(birth_date: date, today: date | None = None) -> int:
    today = today or date.today()
    months = (today.year - birth_date.year) * 12 + (today.month - birth_date.month)
    if today.day < birth_date.day:
        months -= 1
    return max(0, months)
