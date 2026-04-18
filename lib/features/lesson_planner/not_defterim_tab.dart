import 'package:flutter/material.dart';

/// Offline: `not_defterim.md` dosyasinin iceriğini asset olarak paketler ve gosterir.
class NotDefterimTab extends StatelessWidget {
  const NotDefterimTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: DefaultAssetBundle.of(context).loadString('not_defterim.md'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'not_defterim.md okunamadi: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }
        final text = snapshot.data ?? '';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }
}

