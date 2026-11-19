import 'package:flutter/material.dart';

import 'predict_page.dart';
import 'theme.dart';

void main() => runApp(const RevenueEstimatorApp());

class RevenueEstimatorApp extends StatelessWidget {
  const RevenueEstimatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revenue Estimator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const PredictPage(),
    );
  }
}
