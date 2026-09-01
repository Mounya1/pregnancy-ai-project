/// Clock-style duration text shared by the kick counter and the contraction
/// timer. Both screens tick once a second, so this has to be cheap and it has
/// to stay stable in width - a label that jumps from "9:59" to "10:00" and
/// shifts the layout reads as a glitch.
String formatClock(Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  final hours = total.inHours;
  final minutes = total.inMinutes.remainder(60);
  final seconds = total.inSeconds.remainder(60);
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$minutes:$ss';
}

/// Rounded, spoken-aloud duration for summaries: "1 hr 5 min", "48 sec".
String formatApprox(Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  if (total.inMinutes < 1) return '${total.inSeconds} sec';
  if (total.inHours < 1) return '${total.inMinutes} min';
  final minutes = total.inMinutes.remainder(60);
  return minutes == 0 ? '${total.inHours} hr' : '${total.inHours} hr $minutes min';
}
