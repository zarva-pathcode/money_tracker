class LinearRegression {
  final List<double> xValues;
  final List<double> yValues;

  LinearRegression(this.xValues, this.yValues)
    : assert(xValues.length == yValues.length && xValues.length >= 2);

  late final double _slope = _computeSlope();
  late final double _intercept = _computeIntercept();

  double get slope => _slope;
  double get intercept => _intercept;

  double predict(double x) => intercept + slope * x;

  double _computeSlope() {
    final n = xValues.length;
    final sumX = _sum(xValues);
    final sumY = _sum(yValues);
    final sumXY = _zipMap((x, y) => x * y);
    final sumX2 = _sum(xValues.map((x) => x * x).toList());
    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) return 0;
    return (n * sumXY - sumX * sumY) / denom;
  }

  double _computeIntercept() {
    final n = xValues.length;
    return (_sum(yValues) - slope * _sum(xValues)) / n;
  }

  double _sum(List<double> list) => list.isEmpty ? 0 : list.reduce((a, b) => a + b);

  double _zipMap(double Function(double, double) fn) {
    double sum = 0;
    for (var i = 0; i < xValues.length; i++) {
      sum += fn(xValues[i], yValues[i]);
    }
    return sum;
  }
}

List<double> forecastMonths(List<double> historical, int monthsAhead) {
  if (historical.length < 2) {
    return List.filled(monthsAhead, historical.isNotEmpty ? historical.last : 0);
  }
  final x = List.generate(historical.length, (i) => i.toDouble());
  final regression = LinearRegression(x, historical);
  final start = historical.length.toDouble();
  return List.generate(monthsAhead, (i) => regression.predict(start + i));
}

double forecastTrend(List<double> historical) {
  if (historical.length < 2) return 0;
  final x = List.generate(historical.length, (i) => i.toDouble());
  final regression = LinearRegression(x, historical);
  return regression.slope;
}
