from datetime import timedelta
from zoneinfo import ZoneInfo

import numpy as np

from app.schemas.contracts import Metadata, MetricTrend, PatientContext, TrendResponse

METRICS = ["mood", "anxiety", "energy", "sleep", "pain"]


class TrendService:
    def analyze(self, ctx: PatientContext) -> TrendResponse:
        start = ctx.as_of - timedelta(days=ctx.period_days - 1)
        rows = sorted(
            (c for c in ctx.recent_checkins if start <= c.checkin_date <= ctx.as_of),
            key=lambda c: c.checkin_date,
        )
        metrics = {}
        changes = []
        adverse = 0
        better = 0
        for name in METRICS:
            values = np.array([getattr(c, name + "_score") for c in rows], dtype=float)
            dates = [c.checkin_date for c in rows]
            x = np.array([(d - start).days for d in dates], dtype=float)
            enough = len(rows) >= 7 and (dates[-1] - dates[0]).days >= 6
            recent = np.array(
                [v for d, v in zip(dates, values) if d >= ctx.as_of - timedelta(days=2)]
            )
            baseline = np.array(
                [v for d, v in zip(dates, values) if d < ctx.as_of - timedelta(days=2)]
            )
            slope = float(np.polyfit(x, values, 1)[0]) if enough else None
            delta = (
                float(recent.mean() - baseline.mean())
                if len(recent) >= 2 and len(baseline) >= 3
                else None
            )
            direction = "insufficient_data"
            if enough and delta is not None:
                direction = (
                    "increasing"
                    if slope > 0.04 and delta > 0.35
                    else ("declining" if slope < -0.04 and delta < -0.35 else "stable")
                )
            if direction in ["increasing", "declining"]:
                changes.append(
                    f"{name}: {direction}; dibandingkan catatan sebelumnya, bukan diagnosis."
                )
                is_bad = (direction == "increasing") == (name in ["anxiety", "pain"])
                adverse += int(is_bad)
                better += int(not is_bad)
            unusual = []
            if len(baseline) >= 5:
                median = float(np.median(baseline))
                mad = float(np.median(np.abs(baseline - median)))
                scale = max(1.4826 * mad, 0.5)
                unusual = [
                    d.isoformat() for d, v in zip(dates, values) if abs(v - median) / scale >= 3
                ]
            rolling = []
            for d in dates:
                window = [v for dt, v in zip(dates, values) if d - timedelta(days=2) <= dt <= d]
                rolling.append(
                    {
                        "date": d.isoformat(),
                        "mean": round(float(np.mean(window)), 3),
                        "observations": len(window),
                    }
                )
            metrics[name] = MetricTrend(
                direction=direction,
                mean=round(float(values.mean()), 3) if len(values) else None,
                baseline_mean=round(float(baseline.mean()), 3) if len(baseline) else None,
                recent_mean=round(float(recent.mean()), 3) if len(recent) else None,
                slope_per_day=round(slope, 4) if slope is not None else None,
                baseline_delta=round(delta, 3) if delta is not None else None,
                rolling_averages=rolling,
                unusual_dates=unusual,
            )
        patterns = []
        zone = ZoneInfo(ctx.timezone)
        for t in ctx.treatments:
            td = t.scheduled_at.astimezone(zone).date()
            if t.status == "cancelled" or td > ctx.as_of:
                continue
            pre = [
                s.fatigue
                for s in ctx.recent_symptoms
                if -2 <= (s.logged_at.astimezone(zone).date() - td).days <= -1
            ]
            post = [
                s.fatigue
                for s in ctx.recent_symptoms
                if 1 <= (s.logged_at.astimezone(zone).date() - td).days <= 2
                and s.logged_at.astimezone(zone).date() <= ctx.as_of
            ]
            if len(pre) >= 2 and len(post) >= 2:
                delta = float(np.mean(post) - np.mean(pre))
                patterns.append(
                    {
                        "event": t.treatment_type,
                        "date": td.isoformat(),
                        "observation": f"Rata-rata kelelahan berubah {delta:+.1f} poin pada catatan H+1/H+2 dibanding H-2/H-1. Terlihat berdekatan dengan jadwal perawatan; tidak membuktikan sebab-akibat.",
                    }
                )
        signals = [e for e in ctx.emotion_signals if start <= e.date <= ctx.as_of]
        emotions = (
            {
                k: round(float(np.mean([getattr(e.scores, k) for e in signals])), 3)
                for k in ["fear", "sadness", "anxiety", "loneliness", "anger", "hope"]
            }
            if signals
            else {}
        )
        direction = (
            "insufficient_data"
            if all(m.direction == "insufficient_data" for m in metrics.values())
            else ("needs_attention" if adverse else ("improving" if better else "stable"))
        )
        return TrendResponse(
            contains_mock_signals=any(e.mode == "mock" for e in signals),
            period_days=ctx.period_days,
            recorded_days=len(rows),
            coverage=round(len(rows) / ctx.period_days, 3),
            trends={k: v.direction for k, v in metrics.items()},
            metrics=metrics,
            series=rows,
            significant_changes=changes,
            contextual_patterns=patterns,
            emotion_summary=emotions,
            overall_direction=direction,
            metadata=Metadata(
                mode="statistical",
                model_version="trend-1.0",
                method="calendar_slope_rolling_baseline",
            ),
        )
