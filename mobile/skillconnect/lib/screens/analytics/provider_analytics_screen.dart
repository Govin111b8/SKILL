import 'package:flutter/material.dart';

class ProviderAnalyticsScreen extends StatelessWidget {
  const ProviderAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _AnalyticsCard(title: 'Storefront Views', value: '0', subtitle: 'Weekly traffic summary'),
          SizedBox(height: 12),
          _AnalyticsCard(title: 'Booking Conversion', value: '0%', subtitle: 'Leads converted into bookings'),
          SizedBox(height: 12),
          _AnalyticsCard(title: 'Repeat Customers', value: '0', subtitle: 'Returning customers tracked here'),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _AnalyticsCard({required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
